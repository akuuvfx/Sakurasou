import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var lang: LangStore
    @EnvironmentObject var themes: ThemeStore
    @State private var picking = false
    @AppStorage("lastfmKey") private var lastfmKey = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text(lang.t("Réglages", "Settings"))
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                SettingsSection(
                    title: lang.t("Langue", "Language"),
                    footer: lang.t("Toute l'application passe dans la langue choisie.",
                                   "The whole app switches to the chosen language.")
                ) {
                    Picker(lang.t("Langue", "Language"), selection: $lang.code) {
                        Text("Français").tag("fr")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)
                }

                SettingsSection(title: lang.t("Thème", "Theme"), footer: themes.theme.title) {
                    HStack(spacing: 14) {
                        ForEach(AppTheme.allCases) { t in
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) { themes.theme = t }
                            } label: {
                                Circle()
                                    .fill(LinearGradient(colors: [t.accent, t.halo],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(themes.theme == t ? 0.85 : 0), lineWidth: 2)
                                            .padding(-5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    Picker(lang.t("Apparence", "Appearance"), selection: $themes.appearance) {
                        ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                SettingsSection(
                    title: lang.t("Dossier de destination", "Destination folder"),
                    footer: lang.t("Facultatif. Sans dossier mémorisé, « Envoyer le MP3 » ouvre le sélecteur « Enregistrer dans… ».",
                                   "Optional. Without a saved folder, “Send MP3” opens the “Save to…” picker.")
                ) {
                    Label(settings.folderName ?? lang.t("Aucun dossier choisi", "No folder chosen"), systemImage: "folder.fill")
                    Button(lang.t("Choisir / changer le dossier", "Choose / change folder")) { picking = true }
                        .buttonStyle(GlassButtonStyle())
                }

                SettingsSection(
                    title: lang.t("Infos musique (facultatif)", "Music info (optional)"),
                    footer: lang.t("Titre, artiste, album, année et pochette sont remplis automatiquement (iTunes/Deezer, sans clé). Une clé Last.fm gratuite sert de source de secours.",
                                   "Title, artist, album, year and artwork are filled automatically (iTunes/Deezer, no key). A free Last.fm key is used as a fallback source.")
                ) {
                    SecureField(lang.t("Clé API Last.fm", "Last.fm API key"), text: $lastfmKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .glassField()
                    Link(lang.t("Obtenir une clé gratuite", "Get a free key"),
                         destination: URL(string: "https://www.last.fm/api/account/create")!)
                }

                SettingsSection(title: lang.t("Crédits", "Credits")) {
                    Text(lang.t("Le téléchargement repose sur yt-dlp (Unlicense), exécuté directement sur ton iPhone via Python.",
                                "Downloads rely on yt-dlp (Unlicense), running directly on your iPhone via Python."))
                        .font(.footnote)
                    Link("github.com/yt-dlp/yt-dlp", destination: URL(string: "https://github.com/yt-dlp/yt-dlp")!)
                    Text(lang.t("La conversion MP3 utilise FFmpeg et LAME.", "MP3 conversion uses FFmpeg and LAME.")).font(.footnote)
                    Link("ffmpeg.org", destination: URL(string: "https://ffmpeg.org")!)
                    Text(lang.t("Approche d'intégration inspirée de Palladium (tfourj), PythonKit et python-apple-support.",
                                "Integration approach inspired by Palladium (tfourj), PythonKit and python-apple-support."))
                        .font(.footnote).foregroundStyle(.secondary)
                    Link("github.com/tfourj/Palladium", destination: URL(string: "https://github.com/tfourj/Palladium")!)
                }

                Spacer().frame(height: 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { r in
            if case .success(let url) = r { settings.saveFolder(url) }
        }
    }
}
