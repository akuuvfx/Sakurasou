import SwiftUI
import UniformTypeIdentifiers

/// Réglages persistants : dossier de destination (bookmark sécurisé)
final class SettingsStore: ObservableObject {
    @Published var folderName: String = "Aucun dossier choisi"
    private let key = "destFolderBookmark"

    init() {
        if let url = resolveFolder() { folderName = url.lastPathComponent }
    }

    func saveFolder(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        if let data = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: key)
            folderName = url.lastPathComponent
        }
    }

    func resolveFolder() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale) else { return nil }
        if stale { saveFolder(url) }
        return url
    }

    /// Copie le fichier vers le dossier permanent choisi
    func send(_ file: URL) throws {
        guard let folder = resolveFolder() else { throw AppError.noFolder }
        let access = folder.startAccessingSecurityScopedResource()
        defer { if access { folder.stopAccessingSecurityScopedResource() } }
        let dest = folder.appendingPathComponent(file.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) { try FileManager.default.removeItem(at: dest) }
        try FileManager.default.copyItem(at: file, to: dest)
    }
}

enum AppError: LocalizedError {
    case noFolder, badResponse(String)
    var errorDescription: String? {
        switch self {
        case .noFolder: return "Choisis d'abord un dossier dans Réglages."
        case .badResponse(let m): return m
        }
    }
}

/// Fichier MP3 courant partagé entre les onglets 1 et 2
final class LibraryStore: ObservableObject {
    @Published var currentFile: URL?
    @Published var title = ""
    @Published var artist = ""
    @Published var album = ""
    @Published var year = ""
    @Published var artwork: Data?

    func load(_ url: URL) {
        currentFile = url
        let meta = ID3.read(url)
        title = meta.title.isEmpty ? url.deletingPathExtension().lastPathComponent : meta.title
        artist = meta.artist; album = meta.album; year = meta.year; artwork = meta.artwork
    }
}
