import SwiftUI

struct DownloadView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var library: LibraryStore
    @State private var link = ""
    @State private var status = ""
    @State private var loading = false
    @State private var alert: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Sakurasou").font(.largeTitle.bold()).frame(maxWidth: .infinity, alignment: .leading)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lien de la vidéo").font(.headline)
                        TextField("https://…", text: $link)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .padding(12)
                            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        Button {
                            Task { await download() }
                        } label: {
                            HStack {
                                if loading { ProgressView() }
                                Text(loading ? "Téléchargement…" : "Télécharger en MP3")
                            }.frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
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
        .alert("Sakurasou", isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(alert ?? "") }
    }

    func download() async {
        loading = true; status = ""
        defer { loading = false }
        do {
            let url = try await Downloader.downloadMP3(videoURL: link, server: settings.serverURL) { status = $0 }
            library.load(url)
            status = "Terminé ✓"
        } catch {
            alert = error.localizedDescription
        }
    }
}

/// Bouton « Envoyer le MP3 » présent dans les onglets 1 et 2
struct SendButton: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var library: LibraryStore
    @Binding var alert: String?

    var body: some View {
        Button {
            guard let f = library.currentFile else { alert = "Aucun MP3 à envoyer."; return }
            do {
                try settings.send(f)
                alert = "MP3 envoyé dans « \(settings.folderName) »."
            } catch { alert = error.localizedDescription }
        } label: {
            Label("Envoyer le MP3", systemImage: "paperplane.fill")
                .frame(maxWidth: .infinity).padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(.pink)
    }
}
