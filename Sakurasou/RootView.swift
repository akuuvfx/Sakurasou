import SwiftUI

enum AppTab: Hashable {
    case download, edit, settings
}

struct RootView: View {
    @EnvironmentObject var lang: LangStore
    @Environment(\.theme) private var theme
    @State private var tab: AppTab = .download

    var body: some View {
        // TabView natif : barre d'onglets Liquid Glass sur iOS 26
        TabView(selection: $tab) {
            Tab(lang.t("Télécharger", "Download"), systemImage: "arrow.down.circle.fill", value: AppTab.download) {
                DownloadView().background { GlassBackground() }
            }
            Tab("Tags", systemImage: "music.note.list", value: AppTab.edit) {
                EditView().background { GlassBackground() }
            }
            Tab(lang.t("Réglages", "Settings"), systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView().background { GlassBackground() }
            }
        }
        .tint(theme.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
