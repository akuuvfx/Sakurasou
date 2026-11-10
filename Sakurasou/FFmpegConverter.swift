import Foundation
import SwiftFFmpeg

/// Conversion audio -> MP3 (libmp3lame) via le ffmpeg embarqué (SwiftFFmpeg-iOS de tfourj)
enum FFmpegConverter {
    static func toMP3(input: URL, output: URL) async throws {
        try await WorkThread.shared.run {
            try? FileManager.default.removeItem(at: output)
            let args = ["-nostdin", "-y", "-loglevel", "error",
                        "-i", input.path, "-vn",
                        "-c:a", "libmp3lame", "-q:a", "2",
                        output.path]
            do {
                _ = try SwiftFFmpeg.executeDetailed(args)
            } catch SwiftFFmpegError.executionFailed(let code, _, let stderr) {
                throw AppError.badResponse("ffmpeg (\(code)) : \(stderr.suffix(300))")
            }
            guard FileManager.default.fileExists(atPath: output.path) else {
                throw AppError.badResponse(LangStore.tr("La conversion ffmpeg n'a produit aucun fichier.",
                                                        "ffmpeg conversion produced no file."))
            }
        }
    }
}
