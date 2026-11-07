import SwiftUI

public struct DashboardView: View {
    @ObservedObject var manager: XamppManager
    @Binding var selectedTab: NavigationItem

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Sudo Notice Banner (if not configured)
                if !manager.isPasswordlessSudoConfigured {
                    sudoNoticeBanner
                }

                // Hero Status Header Card
                heroHeaderCard

                // Service Controls Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("XAMPP Services")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        if manager.isOperating, let msg = manager.activeOperationMessage {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 14, height: 14)
                                Text(msg)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        ForEach(ServiceType.allCases) { service in
                            ServiceCardView(manager: manager, service: service)
                        }
                    }
                }

                // Quick Links Section
                QuickLinksView(manager: manager)
            }
            .padding(20)
        }
    }

    // MARK: - Hero Header Card

    private var heroHeaderCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(manager.overallStatus.color.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: manager.overallStatus.systemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(manager.overallStatus.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(manager.overallStatus.title)
                            .font(.system(size: 18, weight: .bold))

                        Text("v\(manager.xamppVersion)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(nsColor: .separatorColor).opacity(0.3)))
                    }

                    Text(manager.overallStatus.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Global Actions
                HStack(spacing: 8) {
                    Button {
                        Task { await manager.startAll() }
                    } label: {
                        Label("Start All", systemImage: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(manager.isOperating)

                    Button(role: .destructive) {
                        Task { await manager.stopAll() }
                    } label: {
                        Label("Stop All", systemImage: "stop.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red.opacity(0.85))
                    .disabled(manager.isOperating)

                    Button {
                        Task { await manager.restartAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .help("Restart All Services")
                    .disabled(manager.isOperating)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Sudo Banner

    private var sudoNoticeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Enable 1-Click Control (Passwordless Sudo)")
                    .font(.system(size: 12, weight: .semibold))
                Text("Currently macOS requires your admin password on every start/stop. Enable passwordless sudo for instant controls.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Configure Now") {
                selectedTab = .settings
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }
}

