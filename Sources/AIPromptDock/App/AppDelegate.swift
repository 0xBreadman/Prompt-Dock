import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = PromptStore()
    private let settings = DockSettings()
    private var panelController: FloatingPanelController?
    private var managementController: ManagementWindowController?
    private var radialMenuController: RadialMenuController?
    private var edgeShelfController: EdgeShelfController?
    private var onboardingController: OnboardingWindowController?
    private var statusItem: NSStatusItem?
    private var hotKey: GlobalHotKey?
    private var accessibilityPollTimer: Timer?
    private var hasRequestedAccessibilityThisLaunch = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        store.load()

        let panelController = FloatingPanelController(store: store, settings: settings)
        self.panelController = panelController
        let radialMenuController = RadialMenuController(store: store, settings: settings)
        self.radialMenuController = radialMenuController
        let edgeShelfController = EdgeShelfController(store: store, settings: settings)
        self.edgeShelfController = edgeShelfController
        managementController = ManagementWindowController(store: store, settings: settings)
        onboardingController = OnboardingWindowController(settings: settings)
        configureStatusItem()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showManager),
            name: .openPromptManager,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(registerHotKeys),
            name: .hotKeySettingsChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(requestAccessibilityPermission),
            name: .requestAccessibilityPermission,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(previewRadialMenu),
            name: .previewRadialMenu,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(previewEdgeShelf),
            name: .previewEdgeShelf,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(registerHotKeys),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(registerHotKeys),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )

        hotKey = GlobalHotKey(
            onToggle: { [weak self] in self?.panelController?.toggle() },
            onRadialPressed: { [weak self] in self?.radialMenuController?.begin() },
            onRadialReleased: { [weak self] in self?.radialMenuController?.complete() }
        )
        registerHotKeys()
        edgeShelfController.start()
        panelController.show()
        if !settings.hasCompletedOnboarding {
            onboardingController?.show()
        }

        #if DEBUG
        if CommandLine.arguments.contains("--preview-radial") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                radialMenuController.preview()
            }
        }
        if CommandLine.arguments.contains("--preview-edge") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                edgeShelfController.preview()
            }
        }
        #endif
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "text.bubble.fill", accessibilityDescription: "Prompt Dock")

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "显示 / 隐藏 Prompt Dock", action: #selector(togglePanel), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        let manageItem = NSMenuItem(title: "管理 Prompt 与工作预设…", action: #selector(showManager), keyEquivalent: ",")
        manageItem.target = self
        menu.addItem(manageItem)
        let guideItem = NSMenuItem(title: "使用指南…", action: #selector(showOnboarding), keyEquivalent: "")
        guideItem.target = self
        menu.addItem(guideItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 Prompt Dock", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    @objc private func togglePanel() {
        panelController?.toggle()
    }

    @objc private func showManager() {
        managementController?.show()
    }

    @objc private func showOnboarding() {
        onboardingController?.show()
    }

    @objc private func previewRadialMenu() {
        radialMenuController?.preview()
    }

    @objc private func previewEdgeShelf() {
        edgeShelfController?.preview()
    }

    @objc private func registerHotKeys() {
        guard let result = hotKey?.register(
            toggle: settings.dockShortcut.definition,
            radial: settings.radialShortcut.definition
        ) else { return }
        settings.updateRadialShortcutRegistrationState(result.radialState)

        if result.radialState == .needsAccessibility {
            if !hasRequestedAccessibilityThisLaunch {
                hasRequestedAccessibilityThisLaunch = true
                SingleKeyMonitor.requestAccessibilityAccess()
            }
            startAccessibilityPolling()
        } else {
            accessibilityPollTimer?.invalidate()
            accessibilityPollTimer = nil
        }
    }

    @objc private func requestAccessibilityPermission() {
        hasRequestedAccessibilityThisLaunch = true
        SingleKeyMonitor.requestAccessibilityAccess()
        startAccessibilityPolling()
    }

    private func startAccessibilityPolling() {
        guard accessibilityPollTimer == nil else { return }
        accessibilityPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if SingleKeyMonitor.isAccessibilityTrusted {
                    self.accessibilityPollTimer?.invalidate()
                    self.accessibilityPollTimer = nil
                    self.registerHotKeys()
                }
            }
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
