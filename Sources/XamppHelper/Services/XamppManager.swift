import Foundation
import SwiftUI
import AppKit

@MainActor
public final class XamppManager: ObservableObject {
    @Published public var services: [ServiceType: ServiceInfo] = [:]
    @Published public var overallStatus: OverallStatus = .unknown
    @Published public var isOperating: Bool = false
    @Published public var activeOperationMessage: String? = nil
    @Published public var isPasswordlessSudoConfigured: Bool = false
    @Published public var isRefreshing: Bool = false
    @Published public var consoleLogs: [LogEntry] = []
    @Published public var xamppVersion: String = "8.2.4"
    @Published public var lastUpdated: Date? = nil

    @AppStorage("autoRefreshEnabled") public var autoRefreshEnabled: Bool = true
    @AppStorage("refreshIntervalSeconds") public var refreshIntervalSeconds: Double = 3.0

    private var autoRefreshTask: Task<Void, Never>? = nil

    public init() {
        // Initialize default states
        for type in ServiceType.allCases {
            services[type] = ServiceInfo(type: type, state: .unknown)
        }

        appendLog(level: .info, source: "App", message: "XAMPP Helper initialized.")

        // Initial checks
        Task {
            await checkSudoStatus()
            await refreshStatus()
            startAutoRefresh()
        }
    }

    deinit {
        autoRefreshTask?.cancel()
    }

    // MARK: - Logging

    public func appendLog(level: LogLevel, source: String = "XAMPP", message: String) {
        let entry = LogEntry(level: level, source: source, message: message)
        consoleLogs.insert(entry, at: 0)
        // Keep maximum 500 console logs
        if consoleLogs.count > 500 {
            consoleLogs.removeLast(consoleLogs.count - 500)
        }
    }

    public func clearConsoleLogs() {
        consoleLogs.removeAll()
        appendLog(level: .info, source: "App", message: "Console logs cleared.")
    }

    // MARK: - Status Checking

    public func refreshStatus() async {
        guard !isOperating else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            lastUpdated = Date()
            updateOverallStatus()
        }

        let scriptPath = PathConfig.xamppScript
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            appendLog(level: .error, source: "App", message: "XAMPP script not found at \(scriptPath)")
            for type in ServiceType.allCases {
                services[type]?.state = .error
            }
            return
        }

        // 1. Run xampp statusraw
        let statusrawResult = await CommandExecutor.run(scriptPath, arguments: ["statusraw"])

        var rawApacheRunning = false
        var rawMysqlRunning = false
        var rawFtpRunning = false

        if statusrawResult.isSuccess {
            let output = statusrawResult.stdout
            for line in output.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.starts(with: "VERSION ") {
                    let ver = trimmed.replacingOccurrences(of: "VERSION ", with: "").trimmingCharacters(in: .whitespaces)
                    if !ver.isEmpty { self.xamppVersion = ver }
                } else if trimmed == "APACHE RUNNING" {
                    rawApacheRunning = true
                } else if trimmed == "MYSQL RUNNING" {
                    rawMysqlRunning = true
                } else if trimmed == "PROFTPD RUNNING" {
                    rawFtpRunning = true
                }
            }
        }

        // 2. Perform process checks via pgrep to ensure zero false-negatives
        // (XAMPP's statusraw can report MYSQL NOTRUNNING when running without root due to /var/mysql permissions)
        let mysqlPgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["-f", "/Applications/XAMPP/xamppfiles/sbin/mysqld"])
        let apachePgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["-f", "/Applications/XAMPP/xamppfiles/bin/httpd"])
        let ftpPgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["-f", "/Applications/XAMPP/xamppfiles/sbin/proftpd"])

        let isMysqlActive = rawMysqlRunning || mysqlPgrep.isSuccess
        let isApacheActive = rawApacheRunning || apachePgrep.isSuccess
        let isFtpActive = rawFtpRunning || ftpPgrep.isSuccess

        // Update states unless currently transitioning
        if services[.apache]?.state.isTransitioning != true {
            services[.apache]?.state = isApacheActive ? .running : .stopped
        }
        if services[.mysql]?.state.isTransitioning != true {
            services[.mysql]?.state = isMysqlActive ? .running : .stopped
        }
        if services[.proftpd]?.state.isTransitioning != true {
            services[.proftpd]?.state = isFtpActive ? .running : .stopped
        }
    }

    private func updateOverallStatus() {
        let runningCount = services.values.filter { $0.state == .running }.count
        let totalCount = services.count

        if runningCount == totalCount {
            overallStatus = .allRunning
        } else if runningCount > 0 {
            overallStatus = .partiallyRunning
        } else {
            overallStatus = .allStopped
        }
    }

    // MARK: - Auto Refresh

    public func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.refreshIntervalSeconds ?? 3.0) * 1_000_000_000))
                guard let self = self, self.autoRefreshEnabled, !self.isOperating else { continue }
                await self.refreshStatus()
            }
        }
    }

    // MARK: - Sudo Status & Setup

    public func checkSudoStatus() async {
        isPasswordlessSudoConfigured = await SudoHelper.isConfigured(xamppScript: PathConfig.xamppScript)
    }

    public func installPasswordlessSudo() async {
        isOperating = true
        activeOperationMessage = "Configuring Passwordless Sudo…"
        appendLog(level: .info, source: "Sudo", message: "Configuring passwordless sudo rule in /etc/sudoers.d/xampp-helper...")

        let result = await SudoHelper.installRule(xamppScript: PathConfig.xamppScript)
        if result.isSuccess {
            isPasswordlessSudoConfigured = true
            appendLog(level: .success, source: "Sudo", message: result.combinedOutput)
        } else {
            appendLog(level: .error, source: "Sudo", message: "Failed: \(result.combinedOutput)")
        }

        isOperating = false
        activeOperationMessage = nil
        await checkSudoStatus()
    }

    public func removePasswordlessSudo() async {
        isOperating = true
        activeOperationMessage = "Removing Sudoers Rule…"
        appendLog(level: .info, source: "Sudo", message: "Removing /etc/sudoers.d/xampp-helper...")

        let result = await SudoHelper.removeRule()
        if result.isSuccess {
            isPasswordlessSudoConfigured = false
            appendLog(level: .success, source: "Sudo", message: result.combinedOutput)
        } else {
            appendLog(level: .error, source: "Sudo", message: "Failed: \(result.combinedOutput)")
        }

        isOperating = false
        activeOperationMessage = nil
        await checkSudoStatus()
    }

    // MARK: - Control Actions

    public func startAll() async {
        await executeGlobalAction("start", label: "Starting all XAMPP services…")
    }

    public func stopAll() async {
        await executeGlobalAction("stop", label: "Stopping all XAMPP services…")
    }

    public func restartAll() async {
        await executeGlobalAction("restart", label: "Restarting all XAMPP services…")
    }

    public func start(service: ServiceType) async {
        await executeServiceAction(service: service, action: service.startAction, label: "Starting \(service.rawValue)…")
    }

    public func stop(service: ServiceType) async {
        await executeServiceAction(service: service, action: service.stopAction, label: "Stopping \(service.rawValue)…")
    }

    public func restart(service: ServiceType) async {
        await executeServiceAction(service: service, action: service.reloadAction, label: "Restarting \(service.rawValue)…")
    }

    private func executeGlobalAction(_ action: String, label: String) async {
        isOperating = true
        activeOperationMessage = label

        for type in ServiceType.allCases {
            if action == "stop" {
                services[type]?.state = .stopping
            } else {
                services[type]?.state = .starting
            }
        }

        appendLog(level: .info, source: "Command", message: "Executing: xampp \(action)")

        let result = await CommandExecutor.runElevated(
            command: PathConfig.xamppScript,
            arguments: [action]
        )

        handleCommandResult(result, actionName: action)

        // Wait brief moment for processes to settle
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isOperating = false
        activeOperationMessage = nil
        await refreshStatus()
    }

    private func executeServiceAction(service: ServiceType, action: String, label: String) async {
        isOperating = true
        activeOperationMessage = label

        if action.starts(with: "stop") {
            services[service]?.state = .stopping
        } else {
            services[service]?.state = .starting
        }

        appendLog(level: .info, source: "Command", message: "Executing: xampp \(action)")

        let result = await CommandExecutor.runElevated(
            command: PathConfig.xamppScript,
            arguments: [action]
        )

        handleCommandResult(result, actionName: action)

        try? await Task.sleep(nanoseconds: 800_000_000)
        isOperating = false
        activeOperationMessage = nil
        await refreshStatus()
    }

    private func handleCommandResult(_ result: CommandResult, actionName: String) {
        let output = result.combinedOutput
        if result.isSuccess {
            appendLog(
                level: .success,
                source: "Command",
                message: output.isEmpty ? "Command 'xampp \(actionName)' executed successfully." : output
            )
        } else {
            appendLog(
                level: .error,
                source: "Command",
                message: "Error executing 'xampp \(actionName)': \(output)"
            )
        }
    }

    // MARK: - Quick Launch Shortcuts

    public func openLocalhost() {
        NSWorkspace.shared.open(PathConfig.localhostURL)
        appendLog(level: .info, source: "Shortcut", message: "Opened \(PathConfig.localhostURL.absoluteString) in browser.")
    }

    public func openPhpMyAdmin() {
        NSWorkspace.shared.open(PathConfig.phpMyAdminURL)
        appendLog(level: .info, source: "Shortcut", message: "Opened phpMyAdmin in browser.")
    }

    public func openHtdocs() {
        openPathInFinder(PathConfig.htdocsPath, name: "htdocs")
    }

    public func openXamppFolder() {
        openPathInFinder(PathConfig.basePath, name: "XAMPP Root")
    }

    public func openLogsFolder() {
        openPathInFinder(PathConfig.logsPath, name: "Logs")
    }

    public func openConfigFolder() {
        openPathInFinder(PathConfig.etcPath, name: "Config (etc)")
    }

    public func openConfigFile(path: String, name: String) {
        guard FileManager.default.fileExists(atPath: path) else {
            appendLog(level: .error, source: "Config", message: "File not found: \(path)")
            return
        }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
        appendLog(level: .info, source: "Config", message: "Opened \(name) (\(path)).")
    }

    private func openPathInFinder(_ path: String, name: String) {
        guard FileManager.default.fileExists(atPath: path) else {
            appendLog(level: .error, source: "Finder", message: "Folder not found: \(path)")
            return
        }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
        appendLog(level: .info, source: "Finder", message: "Revealed \(name) folder in Finder.")
    }
}

