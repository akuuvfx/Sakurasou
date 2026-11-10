import SwiftUI

struct DownloadView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var lang: LangStore
    @Environment(\.theme) private var theme
    @State private var link = ""
    @State private var status = ""
    @State private var loading = false
    @State private var alert: String?

    private let card = RoundedRectangle(cornerRadius: 32, style: .continuous)
    private let panel = RoundedRectangle(cornerRadius: 26, style: .continuous)

    var body: some View {
        VStack(spacing: 14) {
            header
            preview
            controls
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .alert("Sakurasou", isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(alert ?? "") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sakurasou").font(.largeTitle.bold())
            Text(lang.t("Télécharge l'audio de tes vidéos en MP3", "Download your videos' audio as MP3"))
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var preview: some View {
        ZStack {
            if loading {
                VStack(spacing: 14) {
                    ProgressView().controlSize(.large).tint(theme.accent)
                    Text(status).font(.footnote).foregroundColor(.secondary)
                }
            } else if let f = library.currentFile {
                VStack(spacing: 12) {
                    if let d = library.artwork, let img = UIImage(data: d) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 170, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 54, weight: .light))
                            .foregroundColor(theme.accent)
                    }
                    Text(library.title.isEmpty ? f.deletingPathExtension().lastPathComponent : library.title)
                        .font(.headline).multilineTextAlignment(.center).lineLimit(2)
                    if !library.artist.isEmpty {
                        Text(library.artist).font(.subheadline).foregroundColor(.secondary)
                    }
                    if !status.isEmpty { Text(status).font(.footnote).foregroundColor(.secondary) }
                }
                .padding(20)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.down.circle").font(.system(size: 40, weight: .light))
                    Text(lang.t("Colle un lien", "Paste a link")).font(.headline)
                    Text(lang.t("Le MP3 apparaîtra ici et dans l'onglet Tags", "The MP3 will appear here and in the Tags tab"))
                        .font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .foregroundColor(.primary)
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(card)
        .glass(card)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                TextField("https://…", text: $link)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                if !link.isEmpty {
                    Button { link = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .glass(panel, interactive: true)

            HStack(spacing: 12) {
                Button {
                    if let s = UIPasteboard.general.string { link = s }
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(GlassCircleStyle())
                .disabled(loading)

                Button {
                    Task { await download() }
                } label: {
                    Text(loading ? lang.t("Téléchargement…", "Downloading…") : lang.t("Télécharger en MP3", "Download as MP3"))
                }
                .buttonStyle(GlassButtonStyle(prominent: true))
                .disabled(loading || link.isEmpty)
                .opacity(loading || link.isEmpty ? 0.45 : 1)
            }

            if library.currentFile != nil { SendButton(alert: $alert) }
        }
    }

    func download() async {
        loading = true; status = ""
        defer { loading = false }
        do {
            let result = try await Downloader.downloadMP3(videoURL: link) { msg in
                Task { @MainActor in status = msg }
            }
            library.load(result.url)   // ajouté automatiquement dans l'onglet Tags
            status = lang.t("Recherche des infos…", "Looking up info…")
            // Remplit titre / artiste / album / année / pochette (modifiables dans l'onglet Tags)
            let meta = await MetadataService.resolve(
                info: result.info, lastfmKey: UserDefaults.standard.string(forKey: "lastfmKey") ?? "")
            if !meta.title.isEmpty { library.title = meta.title }
            library.artist = meta.artist; library.album = meta.album; library.year = meta.year
            if let a = meta.artwork { library.artwork = a }
            try? ID3.write(result.url, meta: ID3Meta(title: library.title, artist: library.artist,
                                                     album: library.album, year: library.year,
                                                     artwork: library.artwork))
            status = lang.t("Terminé ✓", "Done ✓")
        } catch {
            status = ""
            alert = error.localizedDescription
        }
    }
}

/// Bouton « Envoyer le MP3 » : dossier mémorisé si possible, sinon sélecteur « Enregistrer dans… »
struct SendButton: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var lang: LangStore
    @Binding var alert: String?
    @State private var exporting = false

    var body: some View {
        Button { send() } label: {
            Label(lang.t("Envoyer le MP3", "Send MP3"), systemImage: "paperplane.fill")
        }
        .buttonStyle(GlassButtonStyle())
        .disabled(library.currentFile == nil)
        .opacity(library.currentFile == nil ? 0.45 : 1)
        .sheet(isPresented: $exporting) {
            if let f = library.currentFile { ExportPicker(url: f) { exporting = false } }
        }
    }

    private func send() {
        guard let f = library.currentFile else { alert = lang.t("Aucun MP3 à envoyer.", "No MP3 to send."); return }
        if settings.folderName != nil, (try? settings.send(f)) != nil {
            alert = lang.t("MP3 envoyé dans « \(settings.folderName ?? "") ».", "MP3 sent to “\(settings.folderName ?? "")”.")
        } else {
            exporting = true   // pas de dossier mémorisé (ou accès refusé par le certificat)
        }
    }
}
