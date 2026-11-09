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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Crédits").font(.headline)
                        Text("Le téléchargement repose sur yt-dlp (Unlicense), exécuté directement sur ton iPhone via Python.")
                            .font(.footnote)
                        Link("github.com/yt-dlp/yt-dlp", destination: URL(string: "https://github.com/yt-dlp/yt-dlp")!)
                        Text("La conversion MP3 utilise FFmpeg et LAME.").font(.footnote)
                        Link("ffmpeg.org", destination: URL(string: "https://ffmpeg.org")!)
                        Text("Approche d'intégration inspirée de Palladium (tfourj), PythonKit et python-apple-support.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Link("github.com/tfourj/Palladium", destination: URL(string: "https://github.com/tfourj/Palladium")!)
                        Text("Merci aux contributeurs de ces projets ❤️").font(.footnote).foregroundStyle(.secondary)
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
