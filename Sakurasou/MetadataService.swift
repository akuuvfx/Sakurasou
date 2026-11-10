import UIKit

struct TrackMeta {
    var title = "", artist = "", album = "", year = ""
    var artwork: Data?
}

/// Retrouve titre / artiste / album / année / pochette d'un morceau.
/// Sources sans clé : iTunes Search puis Deezer. Clé Last.fm facultative (secours).
enum MetadataService {
    // MARK: Point d'entrée

    static func resolve(info: [String: String], lastfmKey: String) async -> TrackMeta {
        var title = clean(info["track"] ?? info["title"] ?? "")
        var artist = clean(info["artist"] ?? "")
        var artistKnown = !artist.isEmpty
        if artist.isEmpty {
            let parts = title.components(separatedBy: " - ")
            if parts.count >= 2 {                       // « Artiste - Titre »
                artist = clean(parts[0]); title = clean(parts.dropFirst().joined(separator: " - ")); artistKnown = true
            } else {
                artist = clean((info["uploader"] ?? info["channel"] ?? "").replacingOccurrences(of: " - Topic", with: ""))
            }
        }
        var meta = TrackMeta(title: title, artist: artist, album: info["album"] ?? "", year: info["release_year"] ?? "")

        var found = await itunes(title: title, artist: artist, artistKnown: artistKnown)
        if found == nil { found = await deezer(title: title, artist: artist, artistKnown: artistKnown) }
        if found == nil, !lastfmKey.isEmpty { found = await lastfm(title: title, artist: artist, key: lastfmKey) }

        if let f = found {
            if !f.title.isEmpty { meta.title = f.title }
            if !f.artist.isEmpty { meta.artist = f.artist }
            if !f.album.isEmpty { meta.album = f.album }
            if !f.year.isEmpty { meta.year = f.year }
            meta.artwork = f.artwork
        }
        // Pochette de secours : miniature de la vidéo recadrée en carré
        if meta.artwork == nil, let t = info["thumbnail"], let u = URL(string: t) {
            meta.artwork = await squareJPEG(from: u)
        }
        return meta
    }

    // MARK: iTunes (sans clé)

    private static func itunes(title: String, artist: String, artistKnown: Bool) async -> TrackMeta? {
        guard let json = await getJSON("https://itunes.apple.com/search",
                                       ["term": "\(artist) \(title)", "media": "music", "entity": "song", "limit": "8"]),
              let results = json["results"] as? [[String: Any]] else { return nil }
        let cands = results.map { (name: $0["trackName"] as? String ?? "", artist: $0["artistName"] as? String ?? "", raw: $0) }
        guard let pick = choose(cands.map { ($0.name, $0.artist) }, title: title, artist: artist, artistKnown: artistKnown) else { return nil }
        let r = cands[pick].raw
        var m = TrackMeta(title: cands[pick].name, artist: cands[pick].artist,
                          album: r["collectionName"] as? String ?? "",
                          year: String((r["releaseDate"] as? String ?? "").prefix(4)))
        if let a = r["artworkUrl100"] as? String,
           let u = URL(string: a.replacingOccurrences(of: "100x100bb", with: "600x600bb")) {
            m.artwork = await squareJPEG(from: u)
        }
        return m
    }

    // MARK: Deezer (sans clé)

    private static func deezer(title: String, artist: String, artistKnown: Bool) async -> TrackMeta? {
        guard let json = await getJSON("https://api.deezer.com/search", ["q": "\(artist) \(title)", "limit": "8"]),
              let data = json["data"] as? [[String: Any]] else { return nil }
        let cands = data.map { (name: $0["title"] as? String ?? "",
                                artist: ($0["artist"] as? [String: Any])?["name"] as? String ?? "", raw: $0) }
        guard let pick = choose(cands.map { ($0.name, $0.artist) }, title: title, artist: artist, artistKnown: artistKnown) else { return nil }
        let album = cands[pick].raw["album"] as? [String: Any]
        var m = TrackMeta(title: cands[pick].name, artist: cands[pick].artist, album: album?["title"] as? String ?? "")
        if let c = album?["cover_xl"] as? String, let u = URL(string: c) { m.artwork = await squareJPEG(from: u) }
        return m
    }

    // MARK: Last.fm (clé facultative)

    private static func lastfm(title: String, artist: String, key: String) async -> TrackMeta? {
        let base = "https://ws.audioscrobbler.com/2.0/"
        guard let s = await getJSON(base, ["method": "track.search", "track": title, "artist": artist,
                                           "api_key": key, "format": "json", "limit": "5"]),
              let tm = (s["results"] as? [String: Any])?["trackmatches"] as? [String: Any],
              let tracks = tm["track"] as? [[String: Any]],
              let first = tracks.first(where: { plausible(title, $0["name"] as? String ?? "") }),
              let name = first["name"] as? String, let art = first["artist"] as? String else { return nil }
        var m = TrackMeta(title: name, artist: art)
        if let i = await getJSON(base, ["method": "track.getInfo", "track": name, "artist": art, "api_key": key, "format": "json"]),
           let album = (i["track"] as? [String: Any])?["album"] as? [String: Any] {
            m.album = album["title"] as? String ?? ""
            if let imgs = album["image"] as? [[String: Any]],
               let url = imgs.reversed().compactMap({ $0["#text"] as? String }).first(where: { !$0.isEmpty }),
               let u = URL(string: url) { m.artwork = await squareJPEG(from: u) }
        }
        return m
    }

    // MARK: Utilitaires

    /// Choisit le meilleur résultat : titre cohérent, artiste cohérent de préférence.
    private static func choose(_ cands: [(String, String)], title: String, artist: String, artistKnown: Bool) -> Int? {
        let ok = cands.indices.filter { plausible(title, cands[$0].0) }
        if artistKnown, let i = ok.first(where: { plausible(artist, cands[$0].1) }) { return i }
        return ok.first
    }

    private static func norm(_ s: String) -> String {
        s.lowercased().folding(options: .diacriticInsensitive, locale: nil).filter { $0.isLetter || $0.isNumber }
    }
    private static func plausible(_ a: String, _ b: String) -> Bool {
        let x = norm(a), y = norm(b)
        return !x.isEmpty && !y.isEmpty && (x.contains(y) || y.contains(x))
    }

    /// Retire « (Official Video) », « [Lyrics] », « - Topic »…
    static func clean(_ s: String) -> String {
        var r = s.replacingOccurrences(of: " - Topic", with: "")
        let pattern = "\\s*[\\(\\[][^\\)\\]]*(official|video|audio|lyric|clip|visuali[sz]er|remaster|hd|hq|4k)[^\\)\\]]*[\\)\\]]"
        r = r.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
        return r.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func getJSON(_ base: String, _ query: [String: String]) async -> [String: Any]? {
        guard var c = URLComponents(string: base) else { return nil }
        c.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = c.url else { return nil }
        var req = URLRequest(url: url); req.timeoutInterval = 10
        guard let (d, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return (try? JSONSerialization.jsonObject(with: d)) as? [String: Any]
    }

    /// Télécharge une image et la recadre en carré (JPEG)
    static func squareJPEG(from url: URL) async -> Data? {
        var req = URLRequest(url: url); req.timeoutInterval = 10
        guard let (d, _) = try? await URLSession.shared.data(for: req), let img = UIImage(data: d),
              let cg = img.cgImage else { return nil }
        let side = min(cg.width, cg.height)
        let rect = CGRect(x: (cg.width - side) / 2, y: (cg.height - side) / 2, width: side, height: side)
        guard let cropped = cg.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped).jpegData(compressionQuality: 0.88)
    }
}
