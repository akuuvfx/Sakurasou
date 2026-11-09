import Foundation
import SwiftFFmpeg

/// Conversion audio -> MP3 (libmp3lame) via le ffmpeg embarqué (SwiftFFmpeg-iOS de tfourj)
enum FFmpegConverter {
    static func toMP3(input: URL, output: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            try? FileManager.default.removeItem(at: output)
            let args = ["-y", "-i", input.path, "-vn",
                        "-codec:a", "libmp3lame", "-q:a", "2",
                        output.path]
            let code = SwiftFFmpegRunner.run(args)
            guard code == 0, FileManager.default.fileExists(atPath: output.path) else {
                throw AppError.badResponse("La conversion ffmpeg a échoué (code \(code)).")
            }
        }.value
    }
}
