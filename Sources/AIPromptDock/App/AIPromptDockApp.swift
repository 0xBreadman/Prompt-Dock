import SwiftUI

@main
struct AIPromptDockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Prompt Dock 设置…") {
                    NotificationCenter.default.post(name: .openPromptManager, object: nil)
                }
                .keyboardShortcut(",")
            }
        }
    }
}
