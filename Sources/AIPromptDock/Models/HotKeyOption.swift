import Carbon
import Foundation

struct HotKeyDefinition {
    let keyCode: UInt32
    let modifiers: UInt32
}

enum HotKeyRegistrationState: Equatable {
    case checking
    case registered
    case needsAccessibility
    case failed(Int32)
}

enum DockShortcut: String, CaseIterable, Identifiable {
    case commandShiftP
    case commandOptionP
    case controlOptionP

    var id: String { rawValue }

    var title: String {
        switch self {
        case .commandShiftP: "⌘ ⇧ P"
        case .commandOptionP: "⌘ ⌥ P"
        case .controlOptionP: "⌃ ⌥ P"
        }
    }

    var definition: HotKeyDefinition {
        switch self {
        case .commandShiftP:
            HotKeyDefinition(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(cmdKey | shiftKey))
        case .commandOptionP:
            HotKeyDefinition(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(cmdKey | optionKey))
        case .controlOptionP:
            HotKeyDefinition(keyCode: UInt32(kVK_ANSI_P), modifiers: UInt32(controlKey | optionKey))
        }
    }
}

enum RadialShortcut: String, CaseIterable, Identifiable {
    case grave
    case optionSpace
    case controlSpace
    case commandShiftSpace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grave: "·（最快）"
        case .optionSpace: "⌥ Space"
        case .controlSpace: "⌃ Space"
        case .commandShiftSpace: "⌘ ⇧ Space"
        }
    }

    var compactTitle: String {
        self == .grave ? "·" : title
    }

    var definition: HotKeyDefinition {
        switch self {
        case .grave:
            HotKeyDefinition(keyCode: UInt32(kVK_ANSI_Grave), modifiers: 0)
        case .optionSpace:
            HotKeyDefinition(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))
        case .controlSpace:
            HotKeyDefinition(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey))
        case .commandShiftSpace:
            HotKeyDefinition(keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | shiftKey))
        }
    }
}
