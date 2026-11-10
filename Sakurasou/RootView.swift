import SwiftUI

enum AppTab: Hashable {
    case download, edit, settings
}

struct RootView: View {
    @EnvironmentObject var lang: LangStore
    @State private var tab: AppTab = .download

    var body: some View {
        // TabView natif : barre d'onglets Liquid Glass automatique sur iOS 26
        TabView(selection: $tab) {
            Tab(lang.t("Télécharger", "Download"), systemImage: "arrow.down.circle.fill", value: AppTab.download) {
                screen { DownloadView() }
            }
            Tab(lang.t("Tags", "Tags"), systemImage: "music.note.list", value: AppTab.edit) {
                screen { EditView() }
            }
            Tab(lang.t("Réglages", "Settings"), systemImage: "gearshape.fill", value: AppTab.settings) {
                screen { SettingsView() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    private func screen<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.99, green: 0.55, blue: 0.2).opacity(0.6),
                                    Color(red: 0.25, green: 0.15, blue: 0.4).opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            content()
        }
    }
}

/// Carte Liquid Glass (glassEffect natif iOS 26)
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22))
    }
}

/// Champ de saisie Liquid Glass
struct GlassField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14))
    }
}
extension View { func glassField() -> some View { modifier(GlassField()) } }
