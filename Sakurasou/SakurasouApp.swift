import SwiftUI

@main
struct SakurasouApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(library)
        }
    }
}
