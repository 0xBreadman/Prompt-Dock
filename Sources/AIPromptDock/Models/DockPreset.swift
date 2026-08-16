import Foundation

struct DockPreset: Identifiable, Codable, Hashable {
    static let supportedRadialSlotCounts = [4, 6, 8]

    let id: UUID
    var name: String
    var symbolName: String
    var modelBadgeID: String?
    var sortOrder: Int
    var promptIDs: [UUID]
    var quickPromptIDs: [UUID]
    var edgePromptIDs: [UUID]
    var radialSlotCount: Int
    var copiesLastPromptOnQuickTap: Bool

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "square.grid.2x2",
        modelBadgeID: String? = nil,
        sortOrder: Int = 0,
        promptIDs: [UUID] = [],
        quickPromptIDs: [UUID] = [],
        edgePromptIDs: [UUID]? = nil,
        radialSlotCount: Int = 6,
        copiesLastPromptOnQuickTap: Bool = true
    ) {
        let normalizedSlotCount = Self.normalizedRadialSlotCount(radialSlotCount)
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.modelBadgeID = modelBadgeID
        self.sortOrder = sortOrder
        self.promptIDs = promptIDs
        self.quickPromptIDs = Array(quickPromptIDs.prefix(normalizedSlotCount))
        self.edgePromptIDs = edgePromptIDs ?? promptIDs
        self.radialSlotCount = normalizedSlotCount
        self.copiesLastPromptOnQuickTap = copiesLastPromptOnQuickTap
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, symbolName, modelBadgeID, sortOrder, promptIDs, quickPromptIDs
        case edgePromptIDs, radialSlotCount, copiesLastPromptOnQuickTap
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        symbolName = try container.decodeIfPresent(String.self, forKey: .symbolName) ?? "square.grid.2x2"
        modelBadgeID = try container.decodeIfPresent(String.self, forKey: .modelBadgeID)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        promptIDs = try container.decodeIfPresent([UUID].self, forKey: .promptIDs) ?? []
        radialSlotCount = Self.normalizedRadialSlotCount(
            try container.decodeIfPresent(Int.self, forKey: .radialSlotCount) ?? 6
        )
        quickPromptIDs = Array(
            (try container.decodeIfPresent([UUID].self, forKey: .quickPromptIDs) ?? [])
                .prefix(radialSlotCount)
        )
        edgePromptIDs = try container.decodeIfPresent([UUID].self, forKey: .edgePromptIDs)
            ?? promptIDs
        copiesLastPromptOnQuickTap = try container.decodeIfPresent(
            Bool.self,
            forKey: .copiesLastPromptOnQuickTap
        ) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(symbolName, forKey: .symbolName)
        try container.encodeIfPresent(modelBadgeID, forKey: .modelBadgeID)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(promptIDs, forKey: .promptIDs)
        try container.encode(quickPromptIDs, forKey: .quickPromptIDs)
        try container.encode(edgePromptIDs, forKey: .edgePromptIDs)
        try container.encode(radialSlotCount, forKey: .radialSlotCount)
        try container.encode(copiesLastPromptOnQuickTap, forKey: .copiesLastPromptOnQuickTap)
    }

    static func normalizedRadialSlotCount(_ value: Int) -> Int {
        supportedRadialSlotCounts.min { abs($0 - value) < abs($1 - value) } ?? 6
    }
}
