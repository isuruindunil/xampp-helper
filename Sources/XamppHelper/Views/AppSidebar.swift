import SwiftUI

public enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case logs = "Logs & Console"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .logs: return "terminal.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct AppSidebar: View {
    @Binding var selection: NavigationItem
    @ObservedObject var manager: XamppManager

    public var body: some View {
        VStack(spacing: 0) {
            // App Branding Header
            sidebarHeader
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 12)

            // Navigation List
            List(selection: $selection) {
                ForEach(NavigationItem.allCases) { item in
                    NavigationLink(value: item) {
                        HStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .font(.system(size: 14))
                                .frame(width: 20)

                            Text(item.rawValue)
                                .font(.system(size: 13, weight: .medium))

                            Spacer()

                            // Contextual Badge
                            if item == .dashboard {
                                Text("\(manager.activeCount)/\(manager.services.count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(manager.activeCount > 0 ? .green : .secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill((manager.activeCount > 0 ? Color.green : Color.secondary).opacity(0.14)))
                            } else if item == .logs && !manager.consoleLogs.isEmpty {
                                Text("\(manager.consoleLogs.count)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()
                .padding(.horizontal, 12)

            // Sidebar Footer Status
            sidebarFooter
        }
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "server.rack")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("XAMPP Helper")
                    .font(.system(size: 13, weight: .bold, design: .rounded))

                Text("macOS Controller")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var sidebarFooter: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(manager.overallStatus.color)
                .frame(width: 8, height: 8)
                .shadow(color: manager.overallStatus.color.opacity(0.6), radius: 2)

            Text(manager.overallStatus.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            Button {
                Task { await manager.refreshStatus(force: true) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .rotationEffect(.degrees(manager.isRefreshing ? 360 : 0))
                    .animation(manager.isRefreshing ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default, value: manager.isRefreshing)
            }
            .buttonStyle(.plain)
            .help("Refresh Status (⌘R)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
