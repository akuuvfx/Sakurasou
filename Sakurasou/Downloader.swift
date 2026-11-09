import Foundation

/// yt-dlp ne pouvant pas s'exécuter nativement sur iOS, l'app appelle un serveur
/// yt-dlp (ex: `yt-dlp` + petit wrapper HTTP) qui renvoie le MP3.
/// Contrat : GET {server}/mp3?url=<URL encodée>  ->  corps = fichier audio/mpeg
enum Downloader {
    static func downloadMP3(videoURL: String, server: String,
                            progress: @escaping (String) -> Void) async throws -> URL {
        guard !server.isEmpty else { throw AppError.noServer }
        var comps = URLComponents(string: server.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/mp3")
        comps?.queryItems = [URLQueryItem(name: "url", value: videoURL)]
        guard let url = comps?.url else { throw AppError.badResponse("URL serveur invalide") }

        progress("Conversion et téléchargement…")
        var req = URLRequest(url: url)
        req.timeoutInterval = 600
        let (tmp, resp) = try await URLSession.shared.download(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw AppError.badResponse("Le serveur a répondu avec une erreur.")
        }
        var name = "audio"
        if let cd = http.value(forHTTPHeaderField: "Content-Disposition"),
           let r = cd.range(of: "filename=") {
            name = String(cd[r.upperBound...]).trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
            name = (name as NSString).deletingPathExtension
        }
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(name + ".mp3")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tmp, to: dest)
        return dest
    }
}
