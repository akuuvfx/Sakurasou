import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct EditView: View {
    @EnvironmentObject var library: LibraryStore
    @State private var importing = false
    @State private var photo: PhotosPickerItem?
    @State private var alert: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Tags MP3").font(.largeTitle.bold()).frame(maxWidth: .infinity, alignment: .leading)

                GlassCard {
                    Button { importing = true } label: {
                        Label(library.currentFile?.lastPathComponent ?? "Choisir un fichier MP3",
                              systemImage: "doc.badge.plus")
                    }
                }

                if library.currentFile != nil {
                    GlassCard {
                        VStack(spacing: 12) {
                            if let d = library.artwork, let img = UIImage(data: d) {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            PhotosPicker(selection: $photo, matching: .images) {
                                Label("Changer la pochette", systemImage: "photo")
                            }
                            field("Titre", $library.title)
                            field("Artiste", $library.artist)
                            field("Album", $library.album)
                            field("Année", $library.year).keyboardType(.numberPad)
                            Button("Enregistrer les tags") { save() }
                                .buttonStyle(.borderedProminent).tint(.orange)
                        }
                    }
                }
                SendButton(alert: $alert)
            }
            .padding()
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.mp3, .audio]) { r in
            if case .success(let url) = r {
                let ok = url.startAccessingSecurityScopedResource()
                defer { if ok { url.stopAccessingSecurityScopedResource() } }
                let dest = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                try? FileManager.default.copyItem(at: url, to: dest)
                library.load(dest)
            }
        }
        .onChange(of: photo) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data), let jpg = img.jpegData(compressionQuality: 0.85) {
                    library.artwork = jpg
                }
            }
        }
        .alert("Sakurasou", isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(alert ?? "") }
    }

    func field(_ name: String, _ binding: Binding<String>) -> some View {
        TextField(name, text: binding)
            .padding(12)
            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }

    func save() {
        guard let f = library.currentFile else { return }
        do {
            try ID3.write(f, meta: ID3Meta(title: library.title, artist: library.artist,
                                           album: library.album, year: library.year,
                                           artwork: library.artwork))
            alert = "Tags enregistrés."
        } catch { alert = error.localizedDescription }
    }
}
