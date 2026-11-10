import Foundation
import PythonKit

/// Télécharge l'audio d'une vidéo avec yt-dlp (Python embarqué) puis le convertit en MP3.
/// Tout se passe sur l'iPhone, sans serveur.
enum Downloader {
    static func downloadMP3(videoURL: String,
                            progress: @escaping (String) -> Void) async throws -> URL {
        let fm = FileManager.default
        let outDir = fm.temporaryDirectory.appendingPathComponent("dl-" + UUID().uuidString)
        try fm.createDirectory(at: outDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: outDir) }

        // 1) yt-dlp : récupère le meilleur flux audio (sans conversion)
        progress(LangStore.tr("Téléchargement de l'audio…", "Downloading audio…"))
        let audioPath: String = try await WorkThread.shared.run {
            do {
                try PythonRuntime.start()
                let ytdlp = try Python.attemptImport("yt_dlp")
                let template = outDir.path + "/%(title).150B.%(ext)s"
                // Options alignées sur Palladium (nocheckcertificate : pas de CA système en Python iOS)
                let ytArgs: PythonObject = ["player_client": ["android_vr", "ios"]]
                let extractorArgs: PythonObject = ["youtube": ytArgs]
                let opts: PythonObject = [
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
                    "extractor_args": extractorArgs,
                    "postprocessors": []
                ]
                // .throwing : une erreur Python devient une erreur Swift au lieu d'un crash
                let ydl = try ytdlp.YoutubeDL.throwing.dynamicallyCall(withArguments: [opts])
                _ = try ydl.extract_info.throwing.dynamicallyCall(withArguments: [videoURL])
            } catch {
                throw AppError.badResponse("yt-dlp : \(error)")
            }
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
        let tmpMP3 = input.deletingPathExtension().appendingPathExtension("mp3")
        if input.pathExtension.lowercased() == "mp3" {
            // déjà en MP3
        } else {
            try await FFmpegConverter.toMP3(input: input, output: tmpMP3)
        }
        let source = input.pathExtension.lowercased() == "mp3" ? input : tmpMP3

        // 3) Déplace vers un dossier stable (Documents/MP3) pour que l'onglet Tags le garde
        let library = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("MP3")
        try fm.createDirectory(at: library, withIntermediateDirectories: true)
        let final = library.appendingPathComponent(source.lastPathComponent)
        try? fm.removeItem(at: final)
        try fm.moveItem(at: source, to: final)
        return final
    }
}
