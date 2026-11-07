import SwiftUI

public struct ServiceCardView: View {
    @ObservedObject var manager: XamppManager
    let service: ServiceType
    @State private var isHovered: Bool = false

    private var info: ServiceInfo {
        manager.services[service] ?? ServiceInfo(type: service)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row: Icon + Title + Port/PID Pills + Status Badge
            HStack(alignment: .center, spacing: 14) {
                // Squircle Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(iconGradient)
                        .frame(width: 44, height: 44)
                        .shadow(color: iconColor.opacity(0.3), radius: 6, y: 3)

                    Image(systemName: service.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Title and Metadata Pills
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.displayName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))

                    HStack(spacing: 6) {
                        // Port pill
                        Text("Port \(service.defaultPort)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(nsColor: .separatorColor).opacity(0.2)))

                        if service == .apache {
                            Text("SSL 443")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(nsColor: .separatorColor).opacity(0.2)))
                        }

                        // PID pill (if running)
                        if let pid = info.pid, info.state == .running {
                            HStack(spacing: 3) {
                                Text("PID")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text("\(pid)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.12)))
                        }
                    }
                }

                Spacer()

                // Live Status Badge
                StatusBadge(state: info.state)
            }

            Divider()

            // Control Actions Row
            HStack(spacing: 10) {
                if info.state.isTransitioning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                        Text(info.state.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if info.state == .running {
                    Button(role: .destructive) {
                        Task { await manager.stop(service: service) }
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red.opacity(0.85))
                    .disabled(manager.isOperating)

                    Button {
                        Task { await manager.restart(service: service) }
                    } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .disabled(manager.isOperating)
                } else {
                    Button {
                        Task { await manager.start(service: service) }
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(manager.isOperating)
                }

                Spacer()

                // Direct Shortcuts
                if service == .apache && info.state == .running {
                    Button {
                        manager.openLocalhost()
                    } label: {
                        Label("localhost", systemImage: "globe")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else if service == .mysql && info.state == .running {
                    Button {
                        manager.openPhpMyAdmin()
                    } label: {
                        Label("phpMyAdmin", systemImage: "server.rack")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Ellipsis More Menu
                Menu {
                    if service == .apache {
                        Button { manager.openLocalhost() } label: {
                            Label("Open http://localhost", systemImage: "safari")
                        }
                        Button { manager.openPhpInfo() } label: {
                            Label("View phpinfo()", systemImage: "info.circle")
                        }
                        Button { Task { await manager.testApacheConfig() } } label: {
                            Label("Test Apache Syntax (httpd -t)", systemImage: "checkmark.seal")
                        }
                        Button { manager.openConfigFile(path: PathConfig.vhostsConfPath, name: "Virtual Hosts") } label: {
                            Label("Edit Virtual Hosts (httpd-vhosts.conf)", systemImage: "network")
                        }
                    } else if service == .mysql {
                        Button { manager.openPhpMyAdmin() } label: {
                            Label("Open phpMyAdmin", systemImage: "cylinder.split.1x2")
                        }
                        Button { manager.openMysqlTerminal() } label: {
                            Label("Open MySQL in Terminal", systemImage: "terminal")
                        }
                    }

                    Button {
                        manager.openConfigFile(path: service.configPath, name: "\(service.rawValue) Config")
                    } label: {
                        Label("Edit \(service.rawValue) Config", systemImage: "doc.text")
                    }

                    Divider()

                    Button {
                        Task { await manager.restart(service: service) }
                    } label: {
                        Label("Force Restart", systemImage: "arrow.clockwise")
                    }
                    .disabled(manager.isOperating)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24, height: 24)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isHovered ? iconColor.opacity(0.35) : Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.03), radius: isHovered ? 8 : 4, y: 2)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }

    private var iconGradient: LinearGradient {
        switch service {
        case .apache:
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.30, blue: 0.35), Color(red: 0.80, green: 0.15, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mysql:
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.55, blue: 0.15), Color(red: 0.88, green: 0.38, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var iconColor: Color {
        switch service {
        case .apache: return .red
        case .mysql: return .orange
        }
    }
}
