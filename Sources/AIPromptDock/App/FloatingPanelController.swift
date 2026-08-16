import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingPanelController: NSWindowController, NSWindowDelegate {
    private var cancellables = Set<AnyCancellable>()

    init(store: PromptStore, settings: DockSettings) {
        let savedFrame = UserDefaults.standard.string(forKey: "dock.windowFrame")
            .map(NSRectFromString)
        let initialFrame = savedFrame ?? NSRect(x: 0, y: 0, width: 350, height: 620)
        let panel = FloatingPanel(contentRect: initialFrame)

        let rootView = ContentView()
            .environmentObject(store)
            .environmentObject(settings)
        panel.contentView = NSHostingView(rootView: rootView)

        super.init(window: panel)
        panel.delegate = self

        settings.$opacity
            .sink { [weak panel] opacity in
                panel?.alphaValue = opacity
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggle() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            show()
        }
    }

    func show() {
        guard let window else { return }
        let intersectsAnyScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(window.frame)
        }
        if !intersectsAnyScreen {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowDidMove(_ notification: Notification) {
        saveFrame()
    }

    func windowDidResize(_ notification: Notification) {
        saveFrame()
    }

    private func saveFrame() {
        guard let frame = window?.frame else { return }
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: "dock.windowFrame")
    }
}
