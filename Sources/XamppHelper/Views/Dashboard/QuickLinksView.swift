import SwiftUI

public struct QuickLinksView: View {
    @ObservedObject var manager: XamppManager

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 10)
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Links & Shortcuts")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 10) {
                QuickLinkButton(
                    title: "Localhost",
                    subtitle: "http://localhost",
                    systemImage: "safari.fill",
                    accentColor: .blue
                ) {
                    manager.openLocalhost()
                }

                QuickLinkButton(
                    title: "phpMyAdmin",
                    subtitle: "Database GUI",
                    systemImage: "server.rack",
                    accentColor: .orange
                ) {
                    manager.openPhpMyAdmin()
                }

                QuickLinkButton(
                    title: "htdocs Folder",
                    subtitle: "Web Root Directory",
                    systemImage: "folder.fill.badge.gearshape",
                    accentColor: .teal
                ) {
                    manager.openHtdocs()
                }

                QuickLinkButton(
                    title: "XAMPP Directory",
                    subtitle: "/Applications/XAMPP",
                    systemImage: "folder.fill",
                    accentColor: .indigo
                ) {
                    manager.openXamppFolder()
                }

                QuickLinkButton(
                    title: "Config (etc)",
                    subtitle: "httpd.conf, php.ini",
                    systemImage: "gearshape.fill",
                    accentColor: .gray
                ) {
                    manager.openConfigFolder()
                }

                QuickLinkButton(
                    title: "Virtual Hosts",
                    subtitle: "httpd-vhosts.conf",
                    systemImage: "network.badge.shield.half.filled",
                    accentColor: .pink
                ) {
                    manager.openConfigFile(path: PathConfig.vhostsConfPath, name: "Virtual Hosts (httpd-vhosts.conf)")
                }

                QuickLinkButton(
                    title: "Logs Folder",
                    subtitle: "error_log, access_log",
                    systemImage: "doc.text.fill",
                    accentColor: .purple
                ) {
                    manager.openLogsFolder()
                }
            }
        }
    }
}

private struct QuickLinkButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.3) : Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

