import AppKit
import SwiftUI

@MainActor
final class RadialMenuState: ObservableObject {
    @Published var prompts: [PromptItem] = []
    @Published var categories: [UUID: PromptCategory] = [:]
    @Published var selectedIndex: Int?
    @Published var quickTapPrompt: PromptItem?

    var selectedPrompt: PromptItem? {
        guard let selectedIndex, prompts.indices.contains(selectedIndex) else { return nil }
        return prompts[selectedIndex]
    }
}

@MainActor
final class RadialMenuController: NSWindowController {
    private let store: PromptStore
    private let settings: DockSettings
    private let state = RadialMenuState()
    private var trackingTimer: Timer?
    private var previewHideWorkItem: DispatchWorkItem?
    private var anchorPoint = NSPoint.zero
    private var previousSelection: Int?
    private var beganAt: Date?

    init(store: PromptStore, settings: DockSettings) {
        self.store = store
        self.settings = settings

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 430),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: RadialMenuView(state: state))

        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func begin() {
        begin(at: NSEvent.mouseLocation)
    }

    func preview() {
        guard let visible = NSScreen.main?.visibleFrame else { return }
        begin(at: NSPoint(x: visible.midX, y: visible.midY))
        trackingTimer?.invalidate()
        trackingTimer = nil
        if state.prompts.count > 2 {
            state.selectedIndex = 2
        }
        previewHideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.dismissWithoutCopy()
        }
        previewHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }

    private func begin(at point: NSPoint) {
        guard settings.radialMenuEnabled, window?.isVisible != true else { return }
        let prompts = store.radialPrompts
        guard !prompts.isEmpty else { return }

        state.prompts = prompts
        previewHideWorkItem?.cancel()
        previewHideWorkItem = nil
        state.categories = Dictionary(
            uniqueKeysWithValues: store.sortedCategories.map { ($0.id, $0) }
        )
        state.selectedIndex = nil
        state.quickTapPrompt = store.activePreset?.copiesLastPromptOnQuickTap == true
            ? store.lastUsedPromptInActivePreset
            : nil
        previousSelection = nil
        beganAt = .now
        anchorPoint = point
        positionWindow(around: point)
        window?.orderFrontRegardless()

        trackingTimer?.invalidate()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateSelection() }
        }
    }

    func complete() {
        guard window?.isVisible == true else { return }
        previewHideWorkItem?.cancel()
        previewHideWorkItem = nil
        trackingTimer?.invalidate()
        trackingTimer = nil
        let pressDuration = beganAt.map { Date.now.timeIntervalSince($0) } ?? .infinity
        if let prompt = state.selectedPrompt {
            store.copy(prompt)
        } else if pressDuration <= 0.32,
                  let prompt = state.quickTapPrompt {
            store.copy(prompt)
        }
        window?.orderOut(nil)
        state.selectedIndex = nil
        state.quickTapPrompt = nil
        beganAt = nil
    }

    private func dismissWithoutCopy() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        window?.orderOut(nil)
        state.selectedIndex = nil
        state.quickTapPrompt = nil
        beganAt = nil
        previewHideWorkItem = nil
    }

    private func updateSelection() {
        let current = NSEvent.mouseLocation
        let dx = current.x - anchorPoint.x
        let dy = current.y - anchorPoint.y
        let distance = hypot(dx, dy)

        let nextSelection: Int?
        if distance < 48 || state.prompts.isEmpty {
            nextSelection = nil
        } else {
            let count = Double(state.prompts.count)
            let sector = (2 * Double.pi) / count
            var angleFromTopClockwise = atan2(dx, dy)
            if angleFromTopClockwise < 0 { angleFromTopClockwise += 2 * Double.pi }
            nextSelection = Int((angleFromTopClockwise + sector / 2) / sector) % state.prompts.count
        }

        if nextSelection != previousSelection {
            state.selectedIndex = nextSelection
            previousSelection = nextSelection
            if nextSelection != nil {
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .alignment,
                    performanceTime: .now
                )
            }
        }
    }

    private func positionWindow(around point: NSPoint) {
        guard let window else { return }
        let size = window.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var origin = NSPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - size.height - 8)
        window.setFrameOrigin(origin)
    }
}
