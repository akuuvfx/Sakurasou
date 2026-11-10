import SwiftUI

@main
struct SakurasouApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var library = LibraryStore()
    @StateObject private var lang = LangStore.shared
    @StateObject private var themes = ThemeStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(library)
                .environmentObject(lang)
                .environmentObject(themes)
                .environment(\.theme, themes.theme)
                .preferredColorScheme(themes.appearance.scheme)
        }
    }
}
