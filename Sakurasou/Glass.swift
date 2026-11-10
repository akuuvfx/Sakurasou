import SwiftUI

// MARK: - Thèmes (même système que upscayl-ios)

enum AppTheme: String, CaseIterable, Identifiable {
    case sunset, ocean, violet, forest, rose, graphite
    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .ocean: return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .violet: return Color(red: 0.56, green: 0.36, blue: 0.96)
        case .forest: return Color(red: 0.16, green: 0.72, blue: 0.38)
        case .sunset: return Color(red: 1.00, green: 0.50, blue: 0.14)
        case .rose: return Color(red: 1.00, green: 0.30, blue: 0.55)
        case .graphite: return Color(red: 0.50, green: 0.54, blue: 0.62)
        }
    }

    var halo: Color {
        switch self {
        case .ocean: return Color(red: 0.35, green: 0.78, blue: 0.98)
        case .violet: return Color(red: 0.86, green: 0.46, blue: 0.95)
        case .forest: return Color(red: 0.30, green: 0.85, blue: 0.75)
        case .sunset: return Color(red: 1.00, green: 0.30, blue: 0.45)
        case .rose: return Color(red: 1.00, green: 0.62, blue: 0.76)
        case .graphite: return Color(red: 0.36, green: 0.40, blue: 0.48)
        }
    }

    var title: String {
        switch self {
        case .ocean: return LangStore.tr("Océan", "Ocean")
        case .violet: return "Violet"
        case .forest: return LangStore.tr("Forêt", "Forest")
        case .sunset: return LangStore.tr("Coucher de soleil", "Sunset")
        case .rose: return "Rose"
        case .graphite: return "Graphite"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    var title: String {
        switch self {
        case .system: return LangStore.tr("Système", "System")
        case .light: return LangStore.tr("Clair", "Light")
        case .dark: return LangStore.tr("Sombre", "Dark")
        }
    }
}

private struct ThemeKey: EnvironmentKey { static let defaultValue: AppTheme = .sunset }
extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()
    @Published var theme: AppTheme { didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") } }
    @Published var appearance: AppearanceMode { didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appAppearance") } }
    init() {
        theme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "") ?? .sunset
        appearance = AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appAppearance") ?? "") ?? .system
    }
}

// MARK: - Fond et verre

/// Fond statique : deux halos très doux.
struct GlassBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            Color(.systemBackground)
            RadialGradient(colors: [theme.accent.opacity(scheme == .dark ? 0.34 : 0.20), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 430)
            RadialGradient(colors: [theme.halo.opacity(scheme == .dark ? 0.20 : 0.16), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 470)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Vrai Liquid Glass (iOS 26)
    func glass<S: Shape>(_ shape: S, interactive: Bool = false) -> some View {
        Group {
            if interactive { self.glassEffect(.regular.interactive(), in: shape) }
            else { self.glassEffect(.regular, in: shape) }
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label
            .font(.body.weight(.semibold))
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)

        if prominent {
            label
                .foregroundColor(.white)
                .background(
                    Capsule()
                        .fill(theme.accent)
                        .overlay(Capsule().fill(LinearGradient(colors: [Color.white.opacity(0.22), .clear],
                                                               startPoint: .top, endPoint: .center)))
                        .shadow(color: theme.accent.opacity(0.35), radius: 12, y: 5)
                )
        } else {
            label.foregroundColor(.primary).glass(Capsule(), interactive: true)
        }
    }
}

struct GlassCircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .glass(Circle(), interactive: true)
    }
}

/// Carte Liquid Glass
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Section de réglages : titre en capitales + carte verre
struct SettingsSection<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold)).foregroundColor(.secondary)
                .padding(.horizontal, 6)
            GlassCard { VStack(alignment: .leading, spacing: 12) { content } }
            if let footer {
                Text(footer).font(.footnote).foregroundColor(.secondary).padding(.horizontal, 6)
            }
        }
    }
}

/// Champ de saisie en verre
struct GlassField: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(12).glass(RoundedRectangle(cornerRadius: 16, style: .continuous), interactive: true)
    }
}
extension View { func glassField() -> some View { modifier(GlassField()) } }

/// Sélecteur « Enregistrer dans… » du système (marche sans accès permanent au dossier)
struct ExportPicker: UIViewControllerRepresentable {
    let url: URL
    var onDone: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let p = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onDone) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDone: () -> Void
        init(_ d: @escaping () -> Void) { onDone = d }
        func documentPicker(_ c: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { onDone() }
        func documentPickerWasCancelled(_ c: UIDocumentPickerViewController) { onDone() }
    }
}
