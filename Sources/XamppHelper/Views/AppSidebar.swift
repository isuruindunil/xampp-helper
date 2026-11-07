import SwiftUI

public enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case logs = "Logs & Console"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .logs: return "terminal"
        case .settings: return "gearshape"
        }
    }
}

public struct AppSidebar: View {
    @Binding var selection: NavigationItem
    @ObservedObject var manager: XamppManager

    public var body: some View {
        List(NavigationItem.allCases, selection: $selection) { item in
            NavigationLink(value: item) {
                Label(item.rawValue, systemImage: item.icon)
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            sidebarFooter
        }
    }

    private var sidebarFooter: some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 8) {
                Circle()
                    .fill(manager.overallStatus.color)
                    .frame(width: 8, height: 8)

                Text(manager.overallStatus.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Button {
                    Task { await manager.refreshStatus() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .rotationEffect(.degrees(manager.isRefreshing ? 360 : 0))
                        .animation(manager.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: manager.isRefreshing)
                }
                .buttonStyle(.plain)
                .help("Refresh Status")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }
}

