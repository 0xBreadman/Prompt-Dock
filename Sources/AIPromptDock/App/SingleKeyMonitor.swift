import ApplicationServices
import Carbon
import Foundation

final class SingleKeyMonitor {
    enum StartResult {
        case registered
        case needsAccessibility
        case failed
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var keyCode: CGKeyCode = 0
    private var isKeyDown = false
    private let onPressed: () -> Void
    private let onReleased: () -> Void

    init(onPressed: @escaping () -> Void, onReleased: @escaping () -> Void) {
        self.onPressed = onPressed
        self.onReleased = onReleased
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestAccessibilityAccess() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func start(keyCode: UInt32) -> StartResult {
        stop()
        guard Self.isAccessibilityTrusted else { return .needsAccessibility }

        self.keyCode = CGKeyCode(keyCode)
        let eventMask = (CGEventMask(1) << CGEventType.keyDown.rawValue)
            | (CGEventMask(1) << CGEventType.keyUp.rawValue)
        let pointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<SingleKeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            },
            userInfo: pointer
        ) else {
            return Self.isAccessibilityTrusted ? .failed : .needsAccessibility
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return .failed
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return .registered
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
        isKeyDown = false
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp,
              event.getIntegerValueField(.keyboardEventKeycode) == Int64(keyCode) else {
            return Unmanaged.passUnretained(event)
        }

        let shortcutModifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        guard event.flags.intersection(shortcutModifiers).isEmpty else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown {
            if !isKeyDown {
                isKeyDown = true
                DispatchQueue.main.async { [onPressed] in onPressed() }
            }
        } else if isKeyDown {
            isKeyDown = false
            DispatchQueue.main.async { [onReleased] in onReleased() }
        }

        // Swallow the configured single key so it never types into the frontmost app.
        return nil
    }

    deinit {
        stop()
    }
}
