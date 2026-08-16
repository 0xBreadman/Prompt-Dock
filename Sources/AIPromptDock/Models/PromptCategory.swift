import Foundation

struct PromptCategory: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var symbolName: String
    var sortOrder: Int
    var parentID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String,
        sortOrder: Int,
        parentID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.sortOrder = sortOrder
        self.parentID = parentID
    }
}
