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
            await refreshStatus(force: true)
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
        if consoleLogs.count > 500 {
            consoleLogs.removeLast(consoleLogs.count - 500)
        }
    }

    public func clearConsoleLogs() {
        consoleLogs.removeAll()
        appendLog(level: .info, source: "App", message: "Console logs cleared.")
    }

    // MARK: - Status Checking

    public func refreshStatus(force: Bool = false) async {
        guard !isOperating || force else { return }
        isRefreshing = true
        defer {
            isRefreshing = false
            lastUpdated = Date()
            updateOverallStatus()
        }

        let scriptPath = PathConfig.xamppScript
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            appendLog(level: .error, source: "App", message: "XAMPP script not found at \(scriptPath)")
            objectWillChange.send()
            for type in ServiceType.allCases {
                services[type] = ServiceInfo(type: type, state: .error)
            }
            return
        }

        // 1. Run xampp statusraw
        let statusrawResult = await CommandExecutor.run(scriptPath, arguments: ["statusraw"])

        var rawApacheRunning = false
        var rawMysqlRunning = false

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
                }
            }
        }

        // 2. Perform process checks via pgrep to ensure zero false-negatives
        let mysqlPgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["mysqld"])
        let apachePgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["httpd"])

        // 3. Perform socket port checks
        let port3306Open = PortChecker.isPortOpen(port: 3306)
        let port80Open = PortChecker.isPortOpen(port: 80)
        let port443Open = PortChecker.isPortOpen(port: 443)

        let isMysqlActive = rawMysqlRunning || mysqlPgrep.isSuccess || port3306Open
        let isApacheActive = rawApacheRunning || apachePgrep.isSuccess || port80Open || port443Open

        let mysqlPid = Int32(mysqlPgrep.stdout.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines).first ?? "")
        let apachePid = Int32(apachePgrep.stdout.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines).first ?? "")

        // Explicitly update all service states unconditionally with change notification
        objectWillChange.send()
        services[.apache] = ServiceInfo(type: .apache, state: isApacheActive ? .running : .stopped, port: 80, pid: isApacheActive ? apachePid : nil)
        services[.mysql] = ServiceInfo(type: .mysql, state: isMysqlActive ? .running : .stopped, port: 3306, pid: isMysqlActive ? mysqlPid : nil)
    }

    public var activeCount: Int {
        services.values.filter { $0.state == .running }.count
    }

    private func updateOverallStatus() {
        let runningCount = services.values.filter { $0.state == .running }.count
        let totalCount = services.count

        objectWillChange.send()
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
        isOperating = true
        activeOperationMessage = "Starting Apache and MySQL…"

        objectWillChange.send()
        for type in ServiceType.allCases {
            services[type] = ServiceInfo(type: type, state: .starting)
        }

        appendLog(level: .info, source: "Command", message: "Starting Apache Web Server...")
        let apacheResult = await CommandExecutor.runElevated(command: PathConfig.xamppScript, arguments: ["startapache"])
        handleCommandResult(apacheResult, actionName: "startapache")

        appendLog(level: .info, source: "Command", message: "Starting MySQL Database...")
        let mysqlResult = await CommandExecutor.runElevated(command: PathConfig.xamppScript, arguments: ["startmysql"])
        handleCommandResult(mysqlResult, actionName: "startmysql")

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Ensure both started (with fallbacks)
        await ensureServiceStarted(.apache)
        await ensureServiceStarted(.mysql)

        isOperating = false
        activeOperationMessage = nil
        await refreshStatus(force: true)
    }

    public func stopAll() async {
        isOperating = true
        activeOperationMessage = "Stopping Apache and MySQL…"

        objectWillChange.send()
        for type in ServiceType.allCases {
            services[type] = ServiceInfo(type: type, state: .stopping)
        }

        appendLog(level: .info, source: "Command", message: "Stopping Apache Web Server...")
        let apacheResult = await CommandExecutor.runElevated(command: PathConfig.xamppScript, arguments: ["stopapache"])
        handleCommandResult(apacheResult, actionName: "stopapache")

        appendLog(level: .info, source: "Command", message: "Stopping MySQL Database...")
        let mysqlResult = await CommandExecutor.runElevated(command: PathConfig.xamppScript, arguments: ["stopmysql"])
        handleCommandResult(mysqlResult, actionName: "stopmysql")

        // Fallbacks: ensure MySQL and Apache are truly terminated
        await ensureServiceStopped(.mysql)
        await ensureServiceStopped(.apache)

        try? await Task.sleep(nanoseconds: 800_000_000)
        isOperating = false
        activeOperationMessage = nil
        await refreshStatus(force: true)
    }

    public func restartAll() async {
        isOperating = true
        activeOperationMessage = "Restarting Apache and MySQL…"

        objectWillChange.send()
        for type in ServiceType.allCases {
            services[type] = ServiceInfo(type: type, state: .starting)
        }

        appendLog(level: .info, source: "Command", message: "Executing: Restart Apache & MySQL")
        await stopAll()
        try? await Task.sleep(nanoseconds: 600_000_000)
        await startAll()
    }

    public func start(service: ServiceType) async {
        await executeServiceAction(service: service, isStarting: true)
    }

    public func stop(service: ServiceType) async {
        await executeServiceAction(service: service, isStarting: false)
    }

    public func restart(service: ServiceType) async {
        isOperating = true
        activeOperationMessage = "Restarting \(service.rawValue)…"

        objectWillChange.send()
        services[service] = ServiceInfo(type: service, state: .starting)

        appendLog(level: .info, source: "Command", message: "Restarting \(service.rawValue)...")
        await stop(service: service)
        try? await Task.sleep(nanoseconds: 600_000_000)
        await start(service: service)
    }

    private func executeServiceAction(service: ServiceType, isStarting: Bool) async {
        isOperating = true
        let action = isStarting ? service.startAction : service.stopAction
        activeOperationMessage = isStarting ? "Starting \(service.rawValue)…" : "Stopping \(service.rawValue)…"

        objectWillChange.send()
        services[service] = ServiceInfo(type: service, state: isStarting ? .starting : .stopping)

        appendLog(level: .info, source: "Command", message: "Executing: xampp \(action)")

        let result = await CommandExecutor.runElevated(
            command: PathConfig.xamppScript,
            arguments: [action]
        )

        handleCommandResult(result, actionName: action)

        if isStarting {
            try? await Task.sleep(nanoseconds: 800_000_000)
            await ensureServiceStarted(service)
        } else {
            await ensureServiceStopped(service)
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        isOperating = false
        activeOperationMessage = nil
        await refreshStatus(force: true)
    }

    /// Guaranteed termination of leftover processes when stock XAMPP scripts fail to stop them
    private func ensureServiceStopped(_ service: ServiceType) async {
        switch service {
        case .mysql:
            let pgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["mysqld"])
            if pgrep.isSuccess {
                let mysqladmin = (PathConfig.xamppfilesPath as NSString).appendingPathComponent("bin/mysqladmin")
                _ = await CommandExecutor.run(mysqladmin, arguments: ["-u", "root", "shutdown"])
                try? await Task.sleep(nanoseconds: 600_000_000)

                let checkAgain = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["mysqld"])
                if checkAgain.isSuccess {
                    appendLog(level: .warning, source: "MySQL", message: "Terminating mysqld process...")
                    _ = await CommandExecutor.runElevated(command: "/usr/bin/killall", arguments: ["-9", "mysqld"])
                }
            }
        case .apache:
            let pgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["httpd"])
            if pgrep.isSuccess {
                let apachectl = (PathConfig.xamppfilesPath as NSString).appendingPathComponent("bin/apachectl")
                _ = await CommandExecutor.runElevated(command: apachectl, arguments: ["stop"])
                try? await Task.sleep(nanoseconds: 500_000_000)

                let checkAgain = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["httpd"])
                if checkAgain.isSuccess {
                    _ = await CommandExecutor.runElevated(command: "/usr/bin/killall", arguments: ["httpd"])
                }
            }
        }
    }

    /// Guaranteed startup fallback if stock XAMPP script had issues with pid files
    private func ensureServiceStarted(_ service: ServiceType) async {
        switch service {
        case .mysql:
            let pgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["mysqld"])
            if !pgrep.isSuccess && !PortChecker.isPortOpen(port: 3306) {
                appendLog(level: .info, source: "MySQL", message: "Launching MySQL via mysql.server...")
                let mysqlServer = (PathConfig.xamppfilesPath as NSString).appendingPathComponent("bin/mysql.server")
                _ = await CommandExecutor.runElevated(command: mysqlServer, arguments: ["start"])
            }
        case .apache:
            let pgrep = await CommandExecutor.run("/usr/bin/pgrep", arguments: ["httpd"])
            if !pgrep.isSuccess && !PortChecker.isPortOpen(port: 80) {
                let apachectl = (PathConfig.xamppfilesPath as NSString).appendingPathComponent("bin/apachectl")
                _ = await CommandExecutor.runElevated(command: apachectl, arguments: ["start"])
            }
        }
    }

    private func handleCommandResult(_ result: CommandResult, actionName: String) {
        let output = result.combinedOutput
        if result.isSuccess {
            appendLog(
                level: .success,
                source: "Command",
                message: output.isEmpty ? "Command 'xampp \(actionName)' completed." : output
            )
        } else {
            appendLog(
                level: .error,
                source: "Command",
                message: "Command 'xampp \(actionName)' error: \(output)"
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

    public func openMysqlTerminal() {
        let script = """
        tell application "Terminal"
            activate
            do script "\(PathConfig.xamppfilesPath)/bin/mysql -u root"
        end tell
        """
        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            _ = appleScript.executeAndReturnError(&errorDict)
            appendLog(level: .info, source: "MySQL", message: "Launched MySQL CLI in Terminal.")
        }
    }

    public func testApacheConfig() async {
        isOperating = true
        activeOperationMessage = "Testing Apache Config…"
        let httpdBin = (PathConfig.xamppfilesPath as NSString).appendingPathComponent("bin/httpd")
        let result = await CommandExecutor.run(httpdBin, arguments: ["-t"])
        isOperating = false
        activeOperationMessage = nil
        if result.isSuccess {
            appendLog(level: .success, source: "Apache", message: "Apache syntax check: OK")
        } else {
            appendLog(level: .error, source: "Apache", message: "Apache syntax error: \(result.combinedOutput)")
        }
    }

    public func openPhpInfo() {
        if let url = URL(string: "http://localhost/dashboard/phpinfo.php") {
            NSWorkspace.shared.open(url)
            appendLog(level: .info, source: "PHP", message: "Opened phpinfo() in browser.")
        }
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
