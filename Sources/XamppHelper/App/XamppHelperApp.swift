import SwiftUI

@main
struct XamppHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("XAMPP Helper") {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 820, height: 580)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) { }
        }
    }
}

