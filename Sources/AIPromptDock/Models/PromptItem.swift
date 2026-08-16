import Foundation

struct PromptItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var categoryID: UUID
    var tags: [String]
    var primaryModelBadgeID: String?
    var compatibleModelBadgeIDs: [String]
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    var useCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        categoryID: UUID,
        tags: [String] = [],
        primaryModelBadgeID: String? = nil,
        compatibleModelBadgeIDs: [String] = [],
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastUsedAt: Date? = nil,
        useCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.categoryID = categoryID
        self.tags = tags
        self.primaryModelBadgeID = primaryModelBadgeID
        self.compatibleModelBadgeIDs = compatibleModelBadgeIDs.filter { $0 != primaryModelBadgeID }
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, content, categoryID, tags
        case primaryModelBadgeID, compatibleModelBadgeIDs
        case sortOrder, createdAt, updatedAt, lastUsedAt, useCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        categoryID = try container.decode(UUID.self, forKey: .categoryID)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        primaryModelBadgeID = try container.decodeIfPresent(String.self, forKey: .primaryModelBadgeID)
        compatibleModelBadgeIDs = try container.decodeIfPresent([String].self, forKey: .compatibleModelBadgeIDs) ?? []
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        lastUsedAt = try container.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        useCount = try container.decodeIfPresent(Int.self, forKey: .useCount) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(primaryModelBadgeID, forKey: .primaryModelBadgeID)
        try container.encode(compatibleModelBadgeIDs, forKey: .compatibleModelBadgeIDs)
        try container.encode(sortOrder, forKey: .sortOrder)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt)
        try container.encode(useCount, forKey: .useCount)
    }
}
