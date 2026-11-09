import Foundation
import PythonKit

/// Démarre l'interpréteur Python embarqué (python-apple-support) et configure sys.path
enum PythonRuntime {
    private static var started = false
    private static let lock = NSLock()

    static func start() throws {
        lock.lock(); defer { lock.unlock() }
        if started { return }

        let bundle = Bundle.main.bundlePath
        let stdlib = bundle + "/python/lib/python3." + minorVersion()
        let libDynload = stdlib + "/lib-dynload"
        let packages = bundle + "/python-packages"

        setenv("PYTHONHOME", bundle + "/python", 1)
        setenv("PYTHONPATH", [stdlib, libDynload, packages].joined(separator: ":"), 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
        setenv("TMPDIR", NSTemporaryDirectory(), 1)

        // Bibliothèque Python fournie par Python.xcframework
        let libPath = bundle + "/Frameworks/Python.framework/Python"
        PythonLibrary.useLibrary(at: libPath)
        _ = Python.version
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
