import Foundation
import PythonKit

/// Télécharge l'audio d'une vidéo avec yt-dlp (Python embarqué) puis le convertit en MP3.
/// Tout se passe sur l'iPhone, sans serveur.
enum Downloader {
    static func downloadMP3(videoURL: String,
                            progress: @escaping (String) -> Void) async throws -> URL {
        let outDir = FileManager.default.temporaryDirectory.appendingPathComponent("dl-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        // 1) yt-dlp : récupère le meilleur flux audio (sans conversion)
        progress("Téléchargement de l'audio…")
        let audioPath: String = try await Task.detached(priority: .userInitiated) {
            try PythonRuntime.start()
            let sys = Python.import("sys")
            _ = sys
            let ytdlp = try Python.attemptImport("yt_dlp")
            let template = outDir.path + "/%(title)s.%(ext)s"
            let opts: PythonObject = [
                "format": "bestaudio/best",
                "outtmpl": PythonObject(template),
                "noplaylist": true,
                "quiet": true,
                "no_warnings": true,
                "restrictfilenames": false,
                "postprocessors": []
            ]
            let ydl = ytdlp.YoutubeDL(opts)
            let info = ydl.extract_info(videoURL, download: true)
            let prepared = ydl.prepare_filename(info)
            return String(prepared) ?? ""
        }.value

        guard !audioPath.isEmpty, FileManager.default.fileExists(atPath: audioPath) else {
            throw AppError.badResponse("yt-dlp n'a produit aucun fichier.")
        }

        // 2) ffmpeg embarqué : conversion en MP3
        progress("Conversion en MP3…")
        let input = URL(fileURLWithPath: audioPath)
        let mp3 = input.deletingPathExtension().appendingPathExtension("mp3")
        try await FFmpegConverter.toMP3(input: input, output: mp3)
        try? FileManager.default.removeItem(at: input)
        return mp3
    }
}
