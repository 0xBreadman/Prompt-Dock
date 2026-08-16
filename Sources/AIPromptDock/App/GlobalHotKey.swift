import Carbon
import Foundation
import os

struct HotKeyRegistrationResult {
    let handlerStatus: OSStatus
    let toggleStatus: OSStatus
    let radialState: HotKeyRegistrationState
}

final class GlobalHotKey {
    private enum HotKeyID: UInt32 {
        case toggleDock = 1
        case radialMenu = 2
    }

    private var toggleRef: EventHotKeyRef?
    private var radialRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private lazy var singleKeyMonitor = SingleKeyMonitor(
        onPressed: onRadialPressed,
        onReleased: onRadialReleased
    )
    private let onToggle: () -> Void
    private let onRadialPressed: () -> Void
    private let onRadialReleased: () -> Void
    private let logger = Logger(subsystem: "com.ayu.AIPromptDock", category: "GlobalHotKey")

    init(
        onToggle: @escaping () -> Void,
        onRadialPressed: @escaping () -> Void,
        onRadialReleased: @escaping () -> Void
    ) {
        self.onToggle = onToggle
        self.onRadialPressed = onRadialPressed
        self.onRadialReleased = onRadialReleased
    }

    @discardableResult
    func register(toggle: HotKeyDefinition, radial: HotKeyDefinition) -> HotKeyRegistrationResult {
        unregister()

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyReleased))
        ]
        let pointer = Unmanaged.passUnretained(self).toOpaque()

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                let manager = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return status }
                let eventKind = GetEventKind(event)

                DispatchQueue.main.async {
                    manager.handle(id: hotKeyID.id, eventKind: eventKind)
                }
                return noErr
            },
            eventTypes.count,
            &eventTypes,
            pointer,
            &handlerRef
        )

        let signature = OSType(0x41495044) // AIPD
        let toggleID = EventHotKeyID(signature: signature, id: HotKeyID.toggleDock.rawValue)
        let toggleStatus = RegisterEventHotKey(
            toggle.keyCode,
            toggle.modifiers,
            toggleID,
            GetApplicationEventTarget(),
            0,
            &toggleRef
        )

        let radialState: HotKeyRegistrationState
        if radial.modifiers == 0 {
            switch singleKeyMonitor.start(keyCode: radial.keyCode) {
            case .registered:
                radialState = .registered
            case .needsAccessibility:
                radialState = .needsAccessibility
            case .failed:
                radialState = .failed(Int32(eventInternalErr))
            }
        } else {
            let radialID = EventHotKeyID(signature: signature, id: HotKeyID.radialMenu.rawValue)
            let radialStatus = RegisterEventHotKey(
                radial.keyCode,
                radial.modifiers,
                radialID,
                GetApplicationEventTarget(),
                0,
                &radialRef
            )
            radialState = radialStatus == noErr ? .registered : .failed(radialStatus)
        }

        logger.info(
            "Registered hot keys: handler=\(handlerStatus), toggle=\(toggleStatus), radialKey=\(radial.keyCode), radialModifiers=\(radial.modifiers)"
        )
        return HotKeyRegistrationResult(
            handlerStatus: handlerStatus,
            toggleStatus: toggleStatus,
            radialState: radialState
        )
    }

    func unregister() {
        if let toggleRef { UnregisterEventHotKey(toggleRef) }
        if let radialRef { UnregisterEventHotKey(radialRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
        singleKeyMonitor.stop()
        toggleRef = nil
        radialRef = nil
        handlerRef = nil
    }

    private func handle(id: UInt32, eventKind: UInt32) {
        guard let hotKeyID = HotKeyID(rawValue: id) else { return }
        switch (hotKeyID, eventKind) {
        case (.toggleDock, UInt32(kEventHotKeyPressed)):
            onToggle()
        case (.radialMenu, UInt32(kEventHotKeyPressed)):
            onRadialPressed()
        case (.radialMenu, UInt32(kEventHotKeyReleased)):
            onRadialReleased()
        default:
            break
        }
    }

    deinit {
        unregister()
    }
}
