import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var lang: LangStore
    @State private var picking = false

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                Text(lang.t("Réglages", "Settings")).font(.largeTitle.bold()).frame(maxWidth: .infinity, alignment: .leading)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang.t("Langue", "Language")).font(.headline)
                        Picker("", selection: $lang.code) {
                            Text("Français").tag("fr")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(lang.t("Dossier de destination", "Destination folder")).font(.headline)
                        Label(settings.folderName ?? lang.t("Aucun dossier choisi", "No folder chosen"), systemImage: "folder.fill")
                        Text(lang.t("Ce dossier est mémorisé en permanence jusqu'à ce que tu le changes.", "This folder is remembered until you change it."))
                            .font(.footnote).foregroundStyle(.secondary)
                        Button(lang.t("Choisir / changer le dossier", "Choose / change folder")) { picking = true }
                            .buttonStyle(.glassProminent).tint(.orange)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lang.t("Crédits", "Credits")).font(.headline)
                        Text(lang.t("Le téléchargement repose sur yt-dlp (Unlicense), exécuté directement sur ton iPhone via Python.", "Downloads rely on yt-dlp (Unlicense), running directly on your iPhone via Python."))
                            .font(.footnote)
                        Link("github.com/yt-dlp/yt-dlp", destination: URL(string: "https://github.com/yt-dlp/yt-dlp")!)
                        Text(lang.t("La conversion MP3 utilise FFmpeg et LAME.", "MP3 conversion uses FFmpeg and LAME.")).font(.footnote)
                        Link("ffmpeg.org", destination: URL(string: "https://ffmpeg.org")!)
                        Text(lang.t("Approche d'intégration inspirée de Palladium (tfourj), PythonKit et python-apple-support.", "Integration approach inspired by Palladium (tfourj), PythonKit and python-apple-support."))
                            .font(.footnote).foregroundStyle(.secondary)
                        Link("github.com/tfourj/Palladium", destination: URL(string: "https://github.com/tfourj/Palladium")!)
                        Text(lang.t("Merci aux contributeurs de ces projets ❤️", "Thanks to the contributors of these projects ❤️")).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            }
        }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { r in
            if case .success(let url) = r { settings.saveFolder(url) }
        }
    }
}
