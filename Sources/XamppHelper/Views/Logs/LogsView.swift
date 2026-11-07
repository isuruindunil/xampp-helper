import SwiftUI

public enum LogSourceTab: String, CaseIterable, Identifiable {
    case console = "Console"
    case apacheError = "Apache Error"
    case apacheAccess = "Apache Access"
    case phpError = "PHP Error"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .console: return "terminal.fill"
        case .apacheError: return "exclamationmark.triangle.fill"
        case .apacheAccess: return "network"
        case .phpError: return "curlybraces"
        }
    }
}

public struct LogsView: View {
    @ObservedObject var manager: XamppManager
    @State private var selectedTab: LogSourceTab = .console
    @State private var filterText: String = ""
    @State private var fileLogLines: [String] = []
    @State private var isRefreshingFileLog: Bool = false
    @State private var newestOnTop: Bool = true
    @State private var autoScroll: Bool = true

    public var body: some View {
        VStack(spacing: 0) {
            // Top Control Toolbar
            toolbarHeader

            Divider()

            // Main Log Content Area
            ZStack {
                // Sleek terminal background
                Color(nsColor: .underPageBackgroundColor)
                    .ignoresSafeArea()

                if selectedTab == .console {
                    consoleLogList
                } else {
                    fileLogList
                }
            }

            Divider()

            // Bottom Status Bar
            statusBarFooter
        }
        .onChange(of: selectedTab) { _, _ in
            if selectedTab != .console {
                loadFileLogs()
            }
        }
        .onAppear {
            if selectedTab != .console {
                loadFileLogs()
            }
        }
    }

    // MARK: - Toolbar Header

    private var toolbarHeader: some View {
        HStack(spacing: 10) {
            // Source Picker
            Picker("", selection: $selectedTab) {
                ForEach(LogSourceTab.allCases) { tab in
                    Text(tab.rawValue)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(minWidth: 260, maxWidth: 320)

            Spacer(minLength: 8)

            // Search / Filter Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                TextField("Filter logs…", text: $filterText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .frame(minWidth: 80, idealWidth: 110, maxWidth: 140)

                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 1)
            )

            // Action Buttons
            HStack(spacing: 4) {
                // Clear console or reload file
                if selectedTab == .console {
                    Button {
                        manager.clearConsoleLogs()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .help("Clear Console Output")
                } else {
                    Button {
                        loadFileLogs()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .rotationEffect(.degrees(isRefreshingFileLog ? 360 : 0))
                            .animation(isRefreshingFileLog ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshingFileLog)
                    }
                    .buttonStyle(.bordered)
                    .help("Reload Log File")
                }

                // Copy
                Button {
                    copyCurrentLogs()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .help("Copy All Logs to Clipboard")

                // Reveal in Finder
                Button {
                    manager.openLogsFolder()
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .help("Open Logs Folder in Finder")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Console Log List

    private var consoleLogList: some View {
        let filtered = manager.consoleLogs.filter { entry in
            filterText.isEmpty ||
            entry.message.localizedCaseInsensitiveContains(filterText) ||
            entry.source.localizedCaseInsensitiveContains(filterText)
        }

        let displayEntries = newestOnTop ? filtered : filtered.reversed()

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    if displayEntries.isEmpty {
                        emptyStateView(
                            title: filterText.isEmpty ? "No Console Activity Yet" : "No Matches Found",
                            subtitle: filterText.isEmpty ? "Executed commands and daemon status output will appear here." : "Try adjusting your search filter."
                        )
                    } else {
                        ForEach(Array(displayEntries.enumerated()), id: \.element.id) { index, entry in
                            HStack(alignment: .top, spacing: 10) {
                                // Index / Line number
                                Text("\(index + 1)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .frame(width: 32, alignment: .trailing)

                                // Timestamp
                                Text(entry.formattedTimestamp)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)

                                // Source Badge
                                sourcePill(entry.source, level: entry.level)

                                // Message content with multi-line support
                                Text(entry.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(messageColor(for: entry))
                                    .lineSpacing(2)
                                    .textSelection(.enabled)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(entry.level == .error ? Color.red.opacity(0.08) : Color.clear)
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - File Log List

    private var fileLogList: some View {
        let filtered = fileLogLines.filter { line in
            filterText.isEmpty || line.localizedCaseInsensitiveContains(filterText)
        }

        let displayLines = newestOnTop ? Array(filtered.reversed()) : filtered

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                if displayLines.isEmpty {
                    emptyStateView(
                        title: isRefreshingFileLog ? "Loading Logs…" : (filterText.isEmpty ? "Log File Is Empty" : "No Matches Found"),
                        subtitle: isRefreshingFileLog ? "Reading from disk…" : (filterText.isEmpty ? "No entries recorded in this file." : "Try adjusting your search filter.")
                    )
                } else {
                    ForEach(Array(displayLines.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 10) {
                            // Line Number
                            Text("\(index + 1)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.5))
                                .frame(width: 36, alignment: .trailing)

                            // Log Line Text
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(logLineColor(for: line))
                                .lineSpacing(2)
                                .textSelection(.enabled)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(lineHasError(line) ? Color.red.opacity(0.08) : Color.clear)
                        )
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Bottom Status Bar

    private var statusBarFooter: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 6, height: 6)

                Text(selectedTab.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text("•")
                .foregroundColor(.secondary.opacity(0.4))
                .font(.system(size: 10))

            let count = selectedTab == .console ? manager.consoleLogs.count : fileLogLines.count
            Text("\(count) \(count == 1 ? "entry" : "entries")")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)

            if !filterText.isEmpty {
                Text("(filtered by '\(filterText)')")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            }

            Spacer()

            Text(newestOnTop ? "Newest at top" : "Oldest at top")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color(nsColor: .separatorColor).opacity(0.2)))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Helper Views & Functions

    private func sourcePill(_ source: String, level: LogLevel) -> some View {
        Text(source)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(sourceColor(source))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(sourceColor(source).opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(sourceColor(source).opacity(0.25), lineWidth: 0.8)
            )
            .frame(width: 75, alignment: .leading)
    }

    private func sourceColor(_ source: String) -> Color {
        switch source.lowercased() {
        case "command": return .cyan
        case "mysql": return .orange
        case "apache": return .red
        case "proftpd": return .purple
        case "sudo": return .green
        default: return .blue
        }
    }

    private func messageColor(for entry: LogEntry) -> Color {
        switch entry.level {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .primary
        }
    }

    private func lineHasError(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("[error]") || lower.contains("error:") || lower.contains("fatal") || lower.contains("fail")
    }

    private func logLineColor(for line: String) -> Color {
        let lower = line.lowercased()
        if lineHasError(line) {
            return .red
        } else if lower.contains("[warn]") || lower.contains("warning:") {
            return .orange
        } else if lower.contains("[notice]") || lower.contains("ok.") || lower.contains("success") {
            return .green
        }
        return .primary
    }

    private func emptyStateView(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 60)
            Image(systemName: "text.alignleft")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func loadFileLogs() {
        isRefreshingFileLog = true
        let path: String
        switch selectedTab {
        case .console: return
        case .apacheError: path = PathConfig.apacheErrorLog
        case .apacheAccess: path = PathConfig.apacheAccessLog
        case .phpError: path = (PathConfig.logsPath as NSString).appendingPathComponent("php_error_log")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let lines = LogWatcher.readTail(filePath: path, lineCount: 200)
            DispatchQueue.main.async {
                self.fileLogLines = lines
                self.isRefreshingFileLog = false
            }
        }
    }

    private func copyCurrentLogs() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if selectedTab == .console {
            let content = manager.consoleLogs.map { "\($0.formattedTimestamp) [\($0.source)] \($0.message)" }.joined(separator: "\n")
            pasteboard.setString(content, forType: .string)
        } else {
            let content = fileLogLines.joined(separator: "\n")
            pasteboard.setString(content, forType: .string)
        }
    }
}
