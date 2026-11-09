import Foundation
import AVFoundation

struct ID3Meta {
    var title = "", artist = "", album = "", year = ""
    var artwork: Data?
}

/// Lecture/écriture ID3v2.3 minimale (TIT2, TPE1, TALB, TYER, APIC)
enum ID3 {
    static func read(_ url: URL) -> ID3Meta {
        var m = ID3Meta()
        guard let d = try? Data(contentsOf: url), d.count > 10,
              d[0] == 0x49, d[1] == 0x44, d[2] == 0x33 else { return m }
        let ver = d[3]
        let size = syncsafe(d[6..<10])
        var pos = 10
        let end = min(10 + size, d.count)
        while pos + 10 <= end {
            let id = String(bytes: d[pos..<pos+4], encoding: .ascii) ?? ""
            if id.trimmingCharacters(in: .controlCharacters).isEmpty || d[pos] == 0 { break }
            let fsize = ver == 4 ? syncsafe(d[pos+4..<pos+8]) : Int(be32(d[pos+4..<pos+8]))
            let start = pos + 10
            guard fsize > 0, start + fsize <= d.count else { break }
            let body = d[start..<start+fsize]
            switch id {
            case "TIT2": m.title = text(body)
            case "TPE1": m.artist = text(body)
            case "TALB": m.album = text(body)
            case "TYER", "TDRC": m.year = text(body)
            case "APIC": m.artwork = picture(body)
            default: break
            }
            pos = start + fsize
        }
        return m
    }

    static func write(_ url: URL, meta: ID3Meta) throws {
        let old = try Data(contentsOf: url)
        var audio = old
        if old.count > 10, old[0] == 0x49, old[1] == 0x44, old[2] == 0x33 {
            audio = old.subdata(in: (10 + syncsafe(old[6..<10]))..<old.count)
        }
        var frames = Data()
        frames.append(textFrame("TIT2", meta.title))
        frames.append(textFrame("TPE1", meta.artist))
        frames.append(textFrame("TALB", meta.album))
        frames.append(textFrame("TYER", meta.year))
        if let art = meta.artwork {
            var body = Data([0x00])
            body.append("image/jpeg".data(using: .ascii)!); body.append(0)
            body.append(0x03); body.append(0)
            body.append(art)
            frames.append(frame("APIC", body))
        }
        var header = Data("ID3".utf8)
        header.append(contentsOf: [3, 0, 0])
        header.append(contentsOf: ss(frames.count))
        try (header + frames + audio).write(to: url)
    }

    // MARK: helpers
    private static func textFrame(_ id: String, _ s: String) -> Data {
        guard !s.isEmpty else { return Data() }
        var body = Data([0x01, 0xFF, 0xFE])
        body.append(s.data(using: .utf16LittleEndian)!)
        return frame(id, body)
    }
    private static func frame(_ id: String, _ body: Data) -> Data {
        var f = Data(id.utf8)
        var n = UInt32(body.count).bigEndian
        f.append(Data(bytes: &n, count: 4))
        f.append(contentsOf: [0, 0])
        f.append(body)
        return f
    }
    private static func ss(_ n: Int) -> [UInt8] {
        [UInt8((n >> 21) & 0x7F), UInt8((n >> 14) & 0x7F), UInt8((n >> 7) & 0x7F), UInt8(n & 0x7F)]
    }
    private static func syncsafe(_ b: Data.SubSequence) -> Int {
        b.reduce(0) { ($0 << 7) | Int($1 & 0x7F) }
    }
    private static func be32(_ b: Data.SubSequence) -> UInt32 {
        b.reduce(0) { ($0 << 8) | UInt32($1) }
    }
    private static func text(_ b: Data.SubSequence) -> String {
        guard let enc = b.first else { return "" }
        let payload = Data(b.dropFirst())
        let s: String?
        switch enc {
        case 0: s = String(data: payload, encoding: .isoLatin1)
        case 1: s = String(data: payload, encoding: .utf16)
        case 2: s = String(data: payload, encoding: .utf16BigEndian)
        default: s = String(data: payload, encoding: .utf8)
        }
        return (s ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "\0\u{FEFF}"))
    }
    private static func picture(_ b: Data.SubSequence) -> Data? {
        let a = Data(b)
        guard a.count > 4 else { return nil }
        var i = 1
        while i < a.count, a[i] != 0 { i += 1 }   // mime
        i += 2                                     // null + type
        while i < a.count, a[i] != 0 { i += 1 }   // description
        i += 1
        guard i < a.count else { return nil }
        return a.subdata(in: i..<a.count)
    }
}
