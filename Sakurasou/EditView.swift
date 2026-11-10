import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct EditView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var lang: LangStore
    @Environment(\.theme) private var theme
    @State private var importing = false
    @State private var photo: PhotosPickerItem?
    @State private var alert: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.t("Tags MP3", "MP3 Tags")).font(.largeTitle.bold())
                    Text(lang.t("Modifie le titre, l'artiste et la pochette", "Edit title, artist and artwork"))
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button { importing = true } label: {
                    Label(library.currentFile?.lastPathComponent ?? lang.t("Choisir un fichier MP3", "Choose an MP3 file"),
                          systemImage: "doc.badge.plus")
                        .lineLimit(1)
                }
                .buttonStyle(GlassButtonStyle())

                if library.currentFile != nil {
                    GlassCard {
                        VStack(spacing: 12) {
                            if let d = library.artwork, let img = UIImage(data: d) {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 160, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }
                            PhotosPicker(selection: $photo, matching: .images) {
                                Label(lang.t("Changer la pochette", "Change artwork"), systemImage: "photo")
                                    .foregroundColor(theme.accent)
                            }
                            field(lang.t("Titre", "Title"), $library.title)
                            field(lang.t("Artiste", "Artist"), $library.artist)
                            field(lang.t("Album", "Album"), $library.album)
                            field(lang.t("Année", "Year"), $library.year).keyboardType(.numberPad)
                        }
                    }
                    Button { save() } label: { Text(lang.t("Enregistrer les tags", "Save tags")) }
                        .buttonStyle(GlassButtonStyle(prominent: true))
                }
                SendButton(alert: $alert)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.interactively)
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
            .glassField()
    }

    func save() {
        guard let f = library.currentFile else { return }
        do {
            try ID3.write(f, meta: ID3Meta(title: library.title, artist: library.artist,
                                           album: library.album, year: library.year,
                                           artwork: library.artwork))
            alert = lang.t("Tags enregistrés.", "Tags saved.")
        } catch { alert = error.localizedDescription }
    }
}
