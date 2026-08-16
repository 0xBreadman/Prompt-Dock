import AppKit
import Combine
import QuartzCore
import SwiftUI

private final class EdgeTriggerView: NSView {
    var onEnter: (() -> Void)?
    private var trackingAreaReference: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaReference { removeTrackingArea(trackingAreaReference) }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaReference = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        onEnter?()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlAccentColor.withAlphaComponent(0.16).setFill()
        let indicator = NSBezierPath(
            roundedRect: NSRect(x: bounds.midX - 1, y: bounds.midY - 42, width: 2, height: 84),
            xRadius: 1,
            yRadius: 1
        )
        indicator.fill()
    }
}

@MainActor
final class EdgeShelfController: NSObject {
    private let store: PromptStore
    private let settings: DockSettings
    private let triggerPanel: NSPanel
    private let shelfPanel: NSPanel
    private var cancellables = Set<AnyCancellable>()
    private var hideWorkItem: DispatchWorkItem?

    init(store: PromptStore, settings: DockSettings) {
        self.store = store
        self.settings = settings

        triggerPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 7, height: 500),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        shelfPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 304, height: 620),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()
        configurePanels()
        observeSettings()
    }

    func start() {
        updateVisibilityAndPosition()
    }

    func preview() {
        showShelf()
        scheduleHide(delay: 3.0)
    }

    private func configurePanels() {
        for panel in [triggerPanel, shelfPanel] {
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
        }

        triggerPanel.hasShadow = false
        let triggerView = EdgeTriggerView(frame: triggerPanel.contentView?.bounds ?? .zero)
        triggerView.onEnter = { [weak self] in self?.showShelf() }
        triggerPanel.contentView = triggerView

        shelfPanel.hasShadow = true
        shelfPanel.contentView = NSHostingView(
            rootView: EdgeShelfView(
                onHoverChanged: { [weak self] hovering in
                    if hovering { self?.cancelScheduledHide() } else { self?.scheduleHide() }
                },
                onCopied: { [weak self] in self?.scheduleHide(delay: 0.18) }
            )
            .environmentObject(store)
            .environmentObject(settings)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func observeSettings() {
        settings.$edgeShelfEnabled
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateVisibilityAndPosition() }
            .store(in: &cancellables)

        settings.$edgeSide
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateVisibilityAndPosition() }
            .store(in: &cancellables)
    }

    @objc private func screenConfigurationChanged() {
        updateVisibilityAndPosition()
    }

    private func updateVisibilityAndPosition() {
        guard settings.edgeShelfEnabled else {
            triggerPanel.orderOut(nil)
            shelfPanel.orderOut(nil)
            return
        }
        positionPanels(on: NSScreen.main)
        triggerPanel.orderFrontRegardless()
    }

    private func positionPanels(on screen: NSScreen?) {
        guard let visible = screen?.visibleFrame else { return }

        let triggerSize = NSSize(width: 7, height: min(520, visible.height * 0.68))
        let triggerX = settings.edgeSide == .right
            ? visible.maxX - triggerSize.width
            : visible.minX
        triggerPanel.setFrame(
            NSRect(
                x: triggerX,
                y: visible.midY - triggerSize.height / 2,
                width: triggerSize.width,
                height: triggerSize.height
            ),
            display: true
        )

        let shelfSize = NSSize(width: 304, height: min(650, visible.height - 56))
        let shelfX = settings.edgeSide == .right
            ? visible.maxX - shelfSize.width - 8
            : visible.minX + 8
        shelfPanel.setFrame(
            NSRect(
                x: shelfX,
                y: visible.midY - shelfSize.height / 2,
                width: shelfSize.width,
                height: shelfSize.height
            ),
            display: true
        )
    }

    private func showShelf() {
        guard settings.edgeShelfEnabled else { return }
        cancelScheduledHide()
        positionPanels(on: screenAtMouse() ?? NSScreen.main)
        shelfPanel.alphaValue = 0
        shelfPanel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            shelfPanel.animator().alphaValue = 1
        }
    }

    private func scheduleHide(delay: TimeInterval = 0.32) {
        cancelScheduledHide()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.14
                self.shelfPanel.animator().alphaValue = 0
            }, completionHandler: {
                self.shelfPanel.orderOut(nil)
                self.shelfPanel.alphaValue = 1
            })
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func cancelScheduledHide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
    }

    private func screenAtMouse() -> NSScreen? {
        let point = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(point) }
    }
}
