import SwiftUI

public struct ContentView: View {
    @StateObject private var manager = XamppManager()
    @State private var selectedTab: NavigationItem = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            AppSidebar(selection: $selectedTab, manager: manager)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(manager: manager, selectedTab: $selectedTab)
                case .logs:
                    LogsView(manager: manager)
                case .settings:
                    SettingsView(manager: manager)
                }
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if selectedTab != .dashboard {
                        HStack(spacing: 8) {
                            Button {
                                Task { await manager.startAll() }
                            } label: {
                                Image(systemName: "play.fill")
                            }
                            .help("Start All Services (⇧⌘S)")
                            .keyboardShortcut("s", modifiers: [.command, .shift])
                            .disabled(manager.isOperating)

                            Button {
                                Task { await manager.stopAll() }
                            } label: {
                                Image(systemName: "stop.fill")
                            }
                            .help("Stop All Services (⌥⌘S)")
                            .keyboardShortcut("s", modifiers: [.command, .option])
                            .disabled(manager.isOperating)
                        }
                    }

                    Button {
                        Task { await manager.refreshStatus(force: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Status (⌘R)")
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(manager.isOperating)
                }
            }
        }
        .frame(minWidth: 760, idealWidth: 840, minHeight: 520, idealHeight: 600)
    }
}

