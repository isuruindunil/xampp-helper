import SwiftUI

public struct SettingsView: View {
    @ObservedObject var manager: XamppManager
    @State private var sudoStatusFeedback: String? = nil
    @State private var isTestingSudo: Bool = false
    @State private var launchAtLogin: Bool = LaunchAtLoginHelper.isEnabled
    @State private var portStatuses: [PortStatus] = []
    @State private var isScanningPorts: Bool = false

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Sudo Setup Section
                sudoSection

                Divider()

                // XAMPP Paths Section
                pathsSection

                Divider()

                // Auto Refresh & Startup Section
                startupSection

                Divider()

                // Port Diagnostics Section
                portDiagnosticsSection

                Divider()

                // About & System Info
                aboutSection
            }
            .padding(24)
        }
        .onAppear {
            scanPorts()
        }
    }

    // MARK: - Sudo Configuration

    private var sudoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Passwordless Sudo Configuration")
                    .font(.system(size: 15, weight: .bold))

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(manager.isPasswordlessSudoConfigured ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(manager.isPasswordlessSudoConfigured ? "Active" : "Not Configured")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(manager.isPasswordlessSudoConfigured ? .green : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((manager.isPasswordlessSudoConfigured ? Color.green : Color.orange).opacity(0.12))
                )
            }

            Text("macOS requires root privileges to control Apache and ProFTPD. By default, XAMPP Helper prompts for Touch ID or your password each time. Configuring passwordless sudo allows instant 1-click start and stop.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            // Transparency Card
            VStack(alignment: .leading, spacing: 6) {
                Text("Sudoers Rule:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack {
                    Text("\(NSUserName()) ALL=(ALL) NOPASSWD: \(PathConfig.xamppScript)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)

                    Spacer()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor)))

                Text("Saved to /etc/sudoers.d/xampp-helper (validated with visudo)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
            )

            // Buttons
            HStack(spacing: 12) {
                if !manager.isPasswordlessSudoConfigured {
                    Button {
                        Task {
                            await manager.installPasswordlessSudo()
                        }
                    } label: {
                        Label("Enable Passwordless Sudo", systemImage: "key.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(manager.isOperating)
                } else {
                    Button(role: .destructive) {
                        Task {
                            await manager.removePasswordlessSudo()
                        }
                    } label: {
                        Label("Remove Sudoers Rule", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(manager.isOperating)
                }

                Button {
                    testSudo()
                } label: {
                    if isTestingSudo {
                        ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                    } else {
                        Label("Verify Permission", systemImage: "checkmark.shield")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(manager.isOperating || isTestingSudo)

                if let feedback = sudoStatusFeedback {
                    Text(feedback)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Paths Section

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("XAMPP Installation Path")
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TextField("XAMPP Root Path", text: Binding(
                        get: { PathConfig.basePath },
                        set: { PathConfig.basePath = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)

                    Button("Default") {
                        PathConfig.basePath = PathConfig.defaultBasePath
                    }
                    .buttonStyle(.bordered)
                }

                let isValid = PathConfig.isValidInstallation(at: PathConfig.basePath)
                HStack(spacing: 6) {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isValid ? .green : .red)
                    Text(isValid ? "Valid XAMPP installation found." : "Invalid directory: 'xamppfiles/xampp' executable not found.")
                        .font(.system(size: 11))
                        .foregroundColor(isValid ? .green : .red)
                }
            }
        }
    }

    // MARK: - Startup & Background Monitoring

    private var startupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Startup & Monitoring")
                .font(.system(size: 15, weight: .bold))

            Toggle("Launch XAMPP Helper automatically at macOS login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    launchAtLogin = newValue
                    _ = LaunchAtLoginHelper.setEnabled(newValue)
                }
            ))
            .toggleStyle(.switch)

            Toggle("Automatically monitor service status in background", isOn: $manager.autoRefreshEnabled)
                .toggleStyle(.switch)

            if manager.autoRefreshEnabled {
                HStack(spacing: 12) {
                    Text("Check interval:")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Picker("", selection: $manager.refreshIntervalSeconds) {
                        Text("Every 2 seconds").tag(2.0)
                        Text("Every 3 seconds").tag(3.0)
                        Text("Every 5 seconds").tag(5.0)
                        Text("Every 10 seconds").tag(10.0)
                    }
                    .frame(width: 180)
                    .onChange(of: manager.refreshIntervalSeconds) { _, _ in
                        manager.startAutoRefresh()
                    }
                }
            }
        }
    }

    // MARK: - Port Diagnostics

    private var portDiagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Port Diagnostics & Conflict Detection")
                    .font(.system(size: 15, weight: .bold))

                Spacer()

                Button {
                    scanPorts()
                } label: {
                    if isScanningPorts {
                        ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                    } else {
                        Label("Scan Ports", systemImage: "network")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isScanningPorts)
            }

            Text("Detects if required TCP ports (80, 443, 3306, 21) are open or occupied by conflicting software (e.g. macOS native Apache, Homebrew MySQL).")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            if !portStatuses.isEmpty {
                VStack(spacing: 8) {
                    ForEach(portStatuses) { status in
                        HStack(spacing: 12) {
                            Text("Port \(status.port)")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 75, alignment: .leading)

                            Text(status.serviceName)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Spacer()

                            if status.isConflict {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Conflict (Occupied by another app)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            } else if status.isListening {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Active (XAMPP)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.green)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                    Text("Available")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor)))
                    }
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About XAMPP Helper")
                .font(.system(size: 15, weight: .bold))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Developer / Author:")
                        .foregroundColor(.secondary)
                    Text("Isuru Indunil")
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Contact:")
                        .foregroundColor(.secondary)
                    Text("isuruindunil@hotmail.com")
                }
                HStack {
                    Text("App Version:")
                        .foregroundColor(.secondary)
                    Text("1.0.0")
                }
                HStack {
                    Text("Detected XAMPP:")
                        .foregroundColor(.secondary)
                    Text("v\(manager.xamppVersion)")
                }
                HStack {
                    Text("Copyright:")
                        .foregroundColor(.secondary)
                    Text("© 2026 Isuru Indunil. All rights reserved.")
                }
            }
            .font(.system(size: 12, design: .monospaced))
        }
    }

    private func testSudo() {
        isTestingSudo = true
        sudoStatusFeedback = "Checking..."

        Task {
            let active = await SudoHelper.isConfigured(xamppScript: PathConfig.xamppScript)
            manager.isPasswordlessSudoConfigured = active
            isTestingSudo = false
            sudoStatusFeedback = active ? "Verification passed: Sudo works without password!" : "Verification failed: Admin password required."
        }
    }

    private func scanPorts() {
        isScanningPorts = true
        Task {
            let apacheActive = manager.services[.apache]?.state == .running
            let mysqlActive = manager.services[.mysql]?.state == .running
            let ftpActive = manager.services[.proftpd]?.state == .running
            let results = await PortChecker.checkStandardPorts(
                apacheRunning: apacheActive,
                mysqlRunning: mysqlActive,
                ftpRunning: ftpActive
            )
            DispatchQueue.main.async {
                self.portStatuses = results
                self.isScanningPorts = false
            }
        }
    }
}
