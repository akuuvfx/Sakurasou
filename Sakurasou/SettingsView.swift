import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var picking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Réglages").font(.largeTitle.bold()).frame(maxWidth: .infinity, alignment: .leading)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dossier de destination").font(.headline)
                        Label(settings.folderName, systemImage: "folder.fill")
                        Text("Ce dossier est mémorisé en permanence jusqu'à ce que tu le changes.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Choisir / changer le dossier") { picking = true }
                            .buttonStyle(.borderedProminent).tint(.orange)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Serveur yt-dlp").font(.headline)
                        TextField("http://mon-serveur:8080", text: $settings.serverURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        Text("yt-dlp ne pouvant pas tourner nativement sur iOS, l'app interroge ton serveur : GET /mp3?url=…")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Crédits").font(.headline)
                        Text("Le téléchargement et l'extraction audio reposent sur yt-dlp, projet open source du domaine public (Unlicense).")
                            .font(.footnote)
                        Link("github.com/yt-dlp/yt-dlp", destination: URL(string: "https://github.com/yt-dlp/yt-dlp")!)
                        Text("Merci aux contributeurs de yt-dlp ❤️").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { r in
            if case .success(let url) = r { settings.saveFolder(url) }
        }
    }
}
