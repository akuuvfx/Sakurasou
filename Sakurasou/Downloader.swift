import Foundation
import PythonKit

/// Télécharge l'audio d'une vidéo avec yt-dlp (Python embarqué) puis le convertit en MP3.
/// Tout se passe sur l'iPhone, sans serveur.
enum Downloader {
    /// Clients YouTube essayés dans l'ordre : défaut de yt-dlp d'abord (android_vr est bloqué
    /// par YouTube depuis août 2026 → 403), puis visionos, puis web_embedded.
    private static let attempts: [[String]?] = [nil, ["visionos"], ["web_embedded"]]

    private static func short(_ error: Error) -> String {
        let s = "\(error)"
        let head = s.components(separatedBy: "\nTraceback").first ?? s
        return String(head.prefix(400))
    }

    static func downloadMP3(videoURL: String,
                            progress: @escaping (String) -> Void) async throws -> URL {
        let fm = FileManager.default
        let outDir = fm.temporaryDirectory.appendingPathComponent("dl-" + UUID().uuidString)
        try fm.createDirectory(at: outDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: outDir) }

        // 1) yt-dlp : récupère le meilleur flux audio (sans conversion)
        progress(LangStore.tr("Téléchargement de l'audio…", "Downloading audio…"))
        let audioPath: String = try await WorkThread.shared.run {
            var lastError = ""
            var downloaded = false
            do {
                try PythonRuntime.start()
                let ytdlp = try Python.attemptImport("yt_dlp")
                let template = outDir.path + "/%(title).150B.%(ext)s"

                for clients in attempts {
                    // nettoie un éventuel fichier partiel de l'essai précédent
                    for f in (try? FileManager.default.contentsOfDirectory(at: outDir, includingPropertiesForKeys: nil)) ?? [] {
                        try? FileManager.default.removeItem(at: f)
                    }
                    // Options alignées sur Palladium (nocheckcertificate : pas de CA système en Python iOS)
                    var opts: PythonObject = [
                        "format": "bestaudio/best",
                        "outtmpl": PythonObject(template),
                        "noplaylist": true,
                        "quiet": true,
                        "no_warnings": true,
                        "noprogress": true,
                        "nocheckcertificate": true,
                        "cachedir": false,
                        "retries": 5,
                        "socket_timeout": 30,
                        "postprocessors": []
                    ]
                    if let clients {
                        let yt: PythonObject = ["player_client": PythonObject(clients)]
                        let extractorArgs: PythonObject = ["youtube": yt]
                        opts["extractor_args"] = extractorArgs
                    }
                    do {
                        // .throwing : une erreur Python devient une erreur Swift au lieu d'un crash
                        let ydl = try ytdlp.YoutubeDL.throwing.dynamicallyCall(withArguments: [opts])
                        _ = try ydl.extract_info.throwing.dynamicallyCall(withArguments: [videoURL])
                        downloaded = true
                        break
                    } catch {
                        lastError = short(error)
                    }
                }
            } catch {
                lastError = short(error)
            }
            guard downloaded else { throw AppError.badResponse("yt-dlp : \(lastError)") }

            // Fichier téléchargé = le plus gros fichier non partiel du dossier
            let files = (try? FileManager.default.contentsOfDirectory(
                at: outDir, includingPropertiesForKeys: [.fileSizeKey])) ?? []
            let best = files
                .filter { !["part", "ytdl"].contains($0.pathExtension) }
                .max { ((try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                     < ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
            return best?.path ?? ""
        }

        guard !audioPath.isEmpty, fm.fileExists(atPath: audioPath) else {
            throw AppError.badResponse(LangStore.tr("yt-dlp n'a produit aucun fichier.",
                                                    "yt-dlp produced no file."))
        }

        // 2) ffmpeg embarqué : conversion en MP3
        progress(LangStore.tr("Conversion en MP3…", "Converting to MP3…"))
        let input = URL(fileURLWithPath: audioPath)
        let isMP3 = input.pathExtension.lowercased() == "mp3"
        let tmpMP3 = input.deletingPathExtension().appendingPathExtension("mp3")
        if !isMP3 { try await FFmpegConverter.toMP3(input: input, output: tmpMP3) }
        let source = isMP3 ? input : tmpMP3

        // 3) Déplace vers un dossier stable (Documents/MP3) pour que l'onglet Tags le garde
        let library = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("MP3")
        try fm.createDirectory(at: library, withIntermediateDirectories: true)
        let final = library.appendingPathComponent(source.lastPathComponent)
        try? fm.removeItem(at: final)
        try fm.moveItem(at: source, to: final)
        return final
    }
}
