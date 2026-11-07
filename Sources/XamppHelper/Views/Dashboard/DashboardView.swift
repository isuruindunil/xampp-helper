import SwiftUI

public struct DashboardView: View {
    @ObservedObject var manager: XamppManager
    @Binding var selectedTab: NavigationItem
    @State private var timeString: String = "just now"

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Sudo Notice Banner (if not configured)
                if !manager.isPasswordlessSudoConfigured {
                    sudoNoticeBanner
                }

                // Hero Status Header Card
                heroHeaderCard

                // Service Controls Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Services Control")
                            .font(.system(size: 15, weight: .bold, design: .rounded))

                        Text("(\(manager.activeCount)/\(manager.services.count) active)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)

                        Spacer()

                        if manager.isOperating, let msg = manager.activeOperationMessage {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.65)
                                    .frame(width: 14, height: 14)
                                Text(msg)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(nsColor: .controlBackgroundColor)))
                        }
                    }

                    VStack(spacing: 12) {
                        ForEach(ServiceType.allCases) { service in
                            ServiceCardView(manager: manager, service: service)
                        }
                    }
                }

                // Quick Links Section
                QuickLinksView(manager: manager)
            }
            .padding(22)
        }
    }

    // MARK: - Hero Header Card

    private var heroHeaderCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                // Status Glyph
                ZStack {
                    Circle()
                        .fill(manager.overallStatus.color.opacity(0.18))
                        .frame(width: 56, height: 56)

                    Circle()
                        .strokeBorder(manager.overallStatus.color.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 56, height: 56)

                    Image(systemName: manager.overallStatus.systemImage)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(manager.overallStatus.color)
                        .shadow(color: manager.overallStatus.color.opacity(0.4), radius: 6)
                }

                // Title & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(manager.overallStatus.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        Text("XAMPP v\(manager.xamppVersion)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(nsColor: .separatorColor).opacity(0.25)))
                    }

                    HStack(spacing: 6) {
                        Text(manager.overallStatus.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if let date = manager.lastUpdated {
                            Text("•")
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Updated \(formattedRelativeTime(date))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
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
                    .controlSize(.regular)
                    .disabled(manager.isOperating)

                    Button(role: .destructive) {
                        Task { await manager.stopAll() }
                    } label: {
                        Label("Stop All", systemImage: "stop.fill")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red.opacity(0.85))
                    .controlSize(.regular)
                    .disabled(manager.isOperating)

                    Button {
                        Task { await manager.restartAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .help("Restart All Services")
                    .disabled(manager.isOperating)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlBackgroundColor),
                            Color(nsColor: .windowBackgroundColor).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
    }

    // MARK: - Sudo Banner

    private var sudoNoticeBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 34, height: 34)

                Image(systemName: "key.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Enable 1-Click Control (Passwordless Sudo)")
                    .font(.system(size: 13, weight: .bold))
                Text("Currently macOS requires your admin password on every start/stop. Enable passwordless sudo for instant one-click controls.")
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.28), lineWidth: 1)
        )
    }

    private func formattedRelativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 5 { return "just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        return "\(minutes)m ago"
    }
}
