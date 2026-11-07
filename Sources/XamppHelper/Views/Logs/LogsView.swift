import SwiftUI

public enum LogSourceTab: String, CaseIterable, Identifiable {
    case console = "Console Output"
    case apacheError = "Apache Error Log"
    case apacheAccess = "Apache Access Log"
    case phpError = "PHP Error Log"

    public var id: String { rawValue }
}

public struct LogsView: View {
    @ObservedObject var manager: XamppManager
    @State private var selectedTab: LogSourceTab = .console
    @State private var filterText: String = ""
    @State private var fileLogLines: [String] = []
    @State private var isRefreshingFileLog: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            // Log Toolbar
            HStack(spacing: 12) {
                Picker("Log Source", selection: $selectedTab) {
                    ForEach(LogSourceTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Filter logs…", text: $filterText)
                        .textFieldStyle(.plain)
                        .frame(width: 140)
                    if !filterText.isEmpty {
                        Button {
                            filterText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor)))

                // Refresh / Clear / Copy
                if selectedTab == .console {
                    Button {
                        manager.clearConsoleLogs()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Clear Console")
                } else {
                    Button {
                        loadFileLogs()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh File Log")
                }

                Button {
                    copyCurrentLogs()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy to Clipboard")

                Button {
                    manager.openLogsFolder()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Reveal Logs in Finder")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Log Content Area
            if selectedTab == .console {
                consoleLogList
            } else {
                fileLogList
            }
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

    // MARK: - Console Log List

    private var consoleLogList: some View {
        let filtered = manager.consoleLogs.filter { entry in
            filterText.isEmpty ||
            entry.message.localizedCaseInsensitiveContains(filterText) ||
            entry.source.localizedCaseInsensitiveContains(filterText)
        }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Spacer().frame(height: 60)
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(filterText.isEmpty ? "No console logs yet." : "No logs match '\(filterText)'")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(filtered) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Text(entry.formattedTimestamp)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)

                            Text("[\(entry.source)]")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(entry.level.color)

                            Text(entry.message)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 3)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.6))
    }

    // MARK: - File Log List

    private var fileLogList: some View {
        let filtered = fileLogLines.filter { line in
            filterText.isEmpty || line.localizedCaseInsensitiveContains(filterText)
        }

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Spacer().frame(height: 60)
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(isRefreshingFileLog ? "Loading logs…" : "No log entries found.")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(Array(filtered.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.6))
                                .frame(width: 32, alignment: .trailing)

                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(logLineColor(for: line))
                                .textSelection(.enabled)

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 1)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.6))
    }

    private func logLineColor(for line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("[error]") || lower.contains("error:") || lower.contains("fatal") {
            return .red
        } else if lower.contains("[warn]") || lower.contains("warning:") {
            return .orange
        } else if lower.contains("[notice]") || lower.contains("success") {
            return .secondary
        }
        return .primary
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
            let lines = LogWatcher.readTail(filePath: path, lineCount: 150)
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

