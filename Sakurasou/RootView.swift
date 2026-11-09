import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case download = "Télécharger"
    case edit = "Tags"
    case settings = "Réglages"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .download: return "arrow.down.circle.fill"
        case .edit: return "music.note.list"
        case .settings: return "gearshape.fill"
        }
    }
}

struct RootView: View {
    @State private var tab: AppTab = .download
    @Namespace private var ns

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(red: 0.99, green: 0.55, blue: 0.2).opacity(0.5),
                                    Color(red: 0.25, green: 0.15, blue: 0.4).opacity(0.7)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Group {
                switch tab {
                case .download: DownloadView()
                case .edit: EditView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 90)

            GlassTabBar(selection: $tab, ns: ns)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
    }
}

/// Sélecteur Liquid Glass (vrai glassEffect sur iOS 26, matériau verre sinon)
struct GlassTabBar: View {
    @Binding var selection: AppTab
    var ns: Namespace.ID

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { t in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { selection = t }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.icon).font(.system(size: 20, weight: .semibold))
                        Text(t.rawValue).font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selection == t ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selection == t {
                            Capsule()
                                .fill(.white.opacity(0.25))
                                .matchedGeometryEffect(id: "sel", in: ns)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .modifier(GlassBackground())
    }
}

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 0.8))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        }
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.25), lineWidth: 0.8))
    }
}
