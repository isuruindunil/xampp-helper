import SwiftUI

public struct QuickLinksView: View {
    @ObservedObject var manager: XamppManager

    private let columns = [
        GridItem(.adaptive(minimum: 155, maximum: 220), spacing: 12)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Links & Shortcuts")
                .font(.system(size: 15, weight: .bold, design: .rounded))

            // Web Apps Section
            VStack(alignment: .leading, spacing: 8) {
                Text("WEB APPLICATIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: columns, spacing: 10) {
                    QuickLinkTile(
                        title: "Localhost",
                        subtitle: "http://localhost",
                        systemImage: "safari.fill",
                        tintColor: .blue
                    ) {
                        manager.openLocalhost()
                    }

                    QuickLinkTile(
                        title: "phpMyAdmin",
                        subtitle: "Database GUI",
                        systemImage: "server.rack",
                        tintColor: .orange
                    ) {
                        manager.openPhpMyAdmin()
                    }

                    QuickLinkTile(
                        title: "phpinfo()",
                        subtitle: "PHP Configuration",
                        systemImage: "info.circle.fill",
                        tintColor: .indigo
                    ) {
                        manager.openPhpInfo()
                    }
                }
            }

            // Developer Tools & Configs
            VStack(alignment: .leading, spacing: 8) {
                Text("DEVELOPER TOOLS & DIRECTORIES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: columns, spacing: 10) {
                    QuickLinkTile(
                        title: "htdocs Folder",
                        subtitle: "Web Root Directory",
                        systemImage: "folder.fill.badge.gearshape",
                        tintColor: .teal
                    ) {
                        manager.openHtdocs()
                    }

                    QuickLinkTile(
                        title: "Virtual Hosts",
                        subtitle: "httpd-vhosts.conf",
                        systemImage: "network",
                        tintColor: .pink
                    ) {
                        manager.openConfigFile(path: PathConfig.vhostsConfPath, name: "Virtual Hosts")
                    }

                    QuickLinkTile(
                        title: "MySQL Terminal",
                        subtitle: "mysql -u root",
                        systemImage: "terminal.fill",
                        tintColor: .amberColor
                    ) {
                        manager.openMysqlTerminal()
                    }

                    QuickLinkTile(
                        title: "Apache Syntax Test",
                        subtitle: "httpd -t check",
                        systemImage: "checkmark.seal.fill",
                        tintColor: .green
                    ) {
                        Task { await manager.testApacheConfig() }
                    }

                    QuickLinkTile(
                        title: "XAMPP Root",
                        subtitle: "/Applications/XAMPP",
                        systemImage: "folder.fill",
                        tintColor: .secondary
                    ) {
                        manager.openXamppFolder()
                    }

                    QuickLinkTile(
                        title: "Logs Folder",
                        subtitle: "error_log, access_log",
                        systemImage: "doc.text.fill",
                        tintColor: .purple
                    ) {
                        manager.openLogsFolder()
                    }
                }
            }
        }
    }
}

private struct QuickLinkTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tintColor: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tintColor.opacity(0.14))
                        .frame(width: 36, height: 36)

                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(tintColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.35) : Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.06 : 0), radius: 4, y: 2)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

private extension Color {
    static let amberColor = Color(red: 0.95, green: 0.60, blue: 0.10)
}
