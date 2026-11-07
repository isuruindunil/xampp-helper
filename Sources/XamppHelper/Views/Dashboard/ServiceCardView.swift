import SwiftUI

public struct ServiceCardView: View {
    @ObservedObject var manager: XamppManager
    let service: ServiceType

    private var info: ServiceInfo {
        manager.services[service] ?? ServiceInfo(type: service)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row: Icon + Title + Status Badge
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconBackgroundColor)
                        .frame(width: 40, height: 40)

                    Image(systemName: service.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(service.displayName)
                        .font(.system(size: 14, weight: .semibold))

                    HStack(spacing: 6) {
                        Text("Port \(service.defaultPort)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)

                        if service == .apache {
                            Text("• 443 (SSL)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                StatusBadge(state: info.state)
            }

            Divider()

            // Action Buttons
            HStack(spacing: 8) {
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
                            .font(.system(size: 12, weight: .medium))
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
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(manager.isOperating)
                }

                Spacer()

                // Context shortcuts
                Menu {
                    if service == .apache {
                        Button {
                            manager.openLocalhost()
                        } label: {
                            Label("Open http://localhost", systemImage: "safari")
                        }

                        Button {
                            manager.openPhpInfo()
                        } label: {
                            Label("Open phpinfo()", systemImage: "info.circle")
                        }

                        Button {
                            Task { await manager.testApacheConfig() }
                        } label: {
                            Label("Test Apache Syntax (httpd -t)", systemImage: "checkmark.seal")
                        }

                        Button {
                            manager.openConfigFile(path: PathConfig.vhostsConfPath, name: "Virtual Hosts")
                        } label: {
                            Label("Edit Virtual Hosts (httpd-vhosts.conf)", systemImage: "network")
                        }
                    } else if service == .mysql {
                        Button {
                            manager.openPhpMyAdmin()
                        } label: {
                            Label("Open phpMyAdmin", systemImage: "cylinder.split.1x2")
                        }

                        Button {
                            manager.openMysqlTerminal()
                        } label: {
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
    }

    private var iconBackgroundColor: Color {
        switch service {
        case .apache:
            return Color.red.opacity(0.12)
        case .mysql:
            return Color.orange.opacity(0.12)
        case .proftpd:
            return Color.purple.opacity(0.12)
        }
    }

    private var iconColor: Color {
        switch service {
        case .apache:
            return .red
        case .mysql:
            return .orange
        case .proftpd:
            return .purple
        }
    }
}

