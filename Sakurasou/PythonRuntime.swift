import Foundation
import PythonKit

/// Thread persistant à grande pile (comme PythonExecutor de Palladium).
/// Python/PythonKit et ffmpeg doivent toujours tourner sur le même thread dédié :
/// les threads du pool Swift ont une pile trop petite et crashent.
final class WorkThread: @unchecked Sendable {
    static let shared = WorkThread()
    private let cond = NSCondition()
    private var jobs: [() -> Void] = []

    private init() {
        let t = Thread { [self] in loop() }
        t.name = "sakurasou.worker"
        t.stackSize = 16 * 1024 * 1024
        t.qualityOfService = .userInitiated
        t.start()
    }

    private func loop() {
        while true {
            cond.lock()
            while jobs.isEmpty { cond.wait() }
            let job = jobs.removeFirst()
            cond.unlock()
            autoreleasepool { job() }
        }
    }

    func run<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<T, Error>) in
            cond.lock()
            jobs.append { c.resume(with: Result { try work() }) }
            cond.signal()
            cond.unlock()
        }
    }
}

/// Démarre l'interpréteur Python embarqué (python-apple-support) et configure sys.path
enum PythonRuntime {
    private static var started = false

    /// À appeler uniquement depuis WorkThread
    static func start() throws {
        if started { return }

        let bundle = Bundle.main.bundlePath
        let stdlib = bundle + "/python/lib/python3." + minorVersion()
        let libDynload = stdlib + "/lib-dynload"
        let packages = bundle + "/python-packages"

        let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        setenv("PYTHONHOME", bundle + "/python", 1)
        setenv("PYTHONPATH", [packages, stdlib, libDynload].joined(separator: ":"), 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
        setenv("PYTHONNOUSERSITE", "1", 1)
        setenv("TMPDIR", NSTemporaryDirectory(), 1)
        setenv("XDG_CACHE_HOME", caches, 1)

        // Bibliothèque Python fournie par Python.xcframework
        let libPath = bundle + "/Frameworks/Python.framework/Python"
        PythonLibrary.useLibrary(at: libPath)
        _ = try Python.attemptImport("sys")
        started = true
    }

    /// Détecte python3.X dans le bundle
    private static func minorVersion() -> String {
        let dir = Bundle.main.bundlePath + "/python/lib"
        let items = (try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []
        if let p = items.first(where: { $0.hasPrefix("python3.") }) {
            return String(p.dropFirst("python3.".count))
        }
        return "13"
    }
}
