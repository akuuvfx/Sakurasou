import SwiftUI

struct DownloadView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var lang: LangStore
    @State private var link = ""
    @State private var status = ""
    @State private var loading = false
    @State private var alert: String?

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                Text("Sakurasou").font(.largeTitle.bold()).frame(maxWidth: .infinity, alignment: .leading)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lang.t("Lien de la vidéo", "Video link")).font(.headline)
                        TextField("https://…", text: $link)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .glassField()
                        Button {
                            Task { await download() }
                        } label: {
                            HStack {
                                if loading { ProgressView() }
                                Text(loading ? lang.t("Téléchargement…", "Downloading…") : lang.t("Télécharger en MP3", "Download as MP3"))
                            }.frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.orange)
                        .disabled(loading || link.isEmpty)
                        if !status.isEmpty { Text(status).font(.footnote).foregroundStyle(.secondary) }
                    }
                }

                if let f = library.currentFile {
                    GlassCard {
                        Label(f.lastPathComponent, systemImage: "music.note")
                    }
                }
                SendButton(alert: $alert)
            }
            .padding()
            }
        }
        .alert("Sakurasou", isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(alert ?? "") }
    }

    func download() async {
        loading = true; status = ""
        defer { loading = false }
        do {
            let url = try await Downloader.downloadMP3(videoURL: link) { msg in
                Task { @MainActor in status = msg }
            }
            library.load(url)
            status = lang.t("Terminé ✓", "Done ✓")
        } catch {
            alert = error.localizedDescription
        }
    }
}

/// Bouton « Envoyer le MP3 » présent dans les onglets 1 et 2
struct SendButton: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var lang: LangStore
    @Binding var alert: String?

    var body: some View {
        Button {
            guard let f = library.currentFile else { alert = lang.t("Aucun MP3 à envoyer.", "No MP3 to send."); return }
            do {
                try settings.send(f)
                alert = lang.t("MP3 envoyé dans « \(settings.folderName ?? "") ».", "MP3 sent to “\(settings.folderName ?? "")”.")
            } catch { alert = error.localizedDescription }
        } label: {
            Label(lang.t("Envoyer le MP3", "Send MP3"), systemImage: "paperplane.fill")
                .frame(maxWidth: .infinity).padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(.pink)
    }
}
