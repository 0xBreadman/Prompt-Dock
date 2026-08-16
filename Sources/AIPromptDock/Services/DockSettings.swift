import Combine
import Foundation

@MainActor
final class DockSettings: ObservableObject {
    enum EdgeSide: String, CaseIterable, Identifiable {
        case left
        case right

        var id: String { rawValue }
        var title: String { self == .left ? "左侧" : "右侧" }
    }

    private enum Key {
        static let opacity = "dock.opacity"
        static let radialMenuEnabled = "interaction.radialMenuEnabled"
        static let edgeShelfEnabled = "interaction.edgeShelfEnabled"
        static let edgeSide = "interaction.edgeSide"
        static let dockShortcut = "interaction.dockShortcut"
        static let radialShortcut = "interaction.radialShortcut"
        static let radialShortcutRegistrationStatus = "interaction.radialShortcutRegistrationStatus"
        static let hasCompletedOnboarding = "onboarding.completed"
    }

    @Published var opacity: Double {
        didSet {
            UserDefaults.standard.set(opacity, forKey: Key.opacity)
        }
    }

    @Published var radialMenuEnabled: Bool {
        didSet { UserDefaults.standard.set(radialMenuEnabled, forKey: Key.radialMenuEnabled) }
    }

    @Published var edgeShelfEnabled: Bool {
        didSet { UserDefaults.standard.set(edgeShelfEnabled, forKey: Key.edgeShelfEnabled) }
    }

    @Published var edgeSide: EdgeSide {
        didSet { UserDefaults.standard.set(edgeSide.rawValue, forKey: Key.edgeSide) }
    }

    @Published var dockShortcut: DockShortcut {
        didSet {
            UserDefaults.standard.set(dockShortcut.rawValue, forKey: Key.dockShortcut)
            NotificationCenter.default.post(name: .hotKeySettingsChanged, object: nil)
        }
    }

    @Published var radialShortcut: RadialShortcut {
        didSet {
            UserDefaults.standard.set(radialShortcut.rawValue, forKey: Key.radialShortcut)
            NotificationCenter.default.post(name: .hotKeySettingsChanged, object: nil)
        }
    }

    @Published private(set) var radialShortcutRegistrationState: HotKeyRegistrationState = .checking

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }

    init() {
        let defaults = UserDefaults.standard
        let hadPreviousInstallation = defaults.object(forKey: Key.radialMenuEnabled) != nil
        let saved = defaults.double(forKey: Key.opacity)
        opacity = saved == 0 ? 0.96 : min(max(saved, 0.55), 1.0)
        radialMenuEnabled = defaults.object(forKey: Key.radialMenuEnabled) as? Bool ?? true
        edgeShelfEnabled = defaults.object(forKey: Key.edgeShelfEnabled) as? Bool ?? true
        edgeSide = EdgeSide(
            rawValue: defaults.string(forKey: Key.edgeSide) ?? "right"
        ) ?? .right
        dockShortcut = DockShortcut(
            rawValue: defaults.string(forKey: Key.dockShortcut) ?? ""
        ) ?? .commandShiftP
        radialShortcut = RadialShortcut(
            rawValue: defaults.string(forKey: Key.radialShortcut) ?? ""
        ) ?? .grave
        hasCompletedOnboarding = defaults.object(forKey: Key.hasCompletedOnboarding) as? Bool
            ?? hadPreviousInstallation
    }

    func updateRadialShortcutRegistrationState(_ state: HotKeyRegistrationState) {
        radialShortcutRegistrationState = state
        switch state {
        case .checking:
            UserDefaults.standard.removeObject(forKey: Key.radialShortcutRegistrationStatus)
        case .registered:
            UserDefaults.standard.set("registered", forKey: Key.radialShortcutRegistrationStatus)
        case .needsAccessibility:
            UserDefaults.standard.set("needsAccessibility", forKey: Key.radialShortcutRegistrationStatus)
        case .failed(let status):
            UserDefaults.standard.set("failed:\(status)", forKey: Key.radialShortcutRegistrationStatus)
        }
    }
}
