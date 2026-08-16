import Foundation

protocol PromptRepository {
    func load() throws -> PromptLibrary
    func save(_ library: PromptLibrary) throws
    func export(_ library: PromptLibrary, to destination: URL) throws
    func importLibrary(from source: URL) throws -> PromptLibrary
}

enum PromptRepositoryError: LocalizedError {
    case unsupportedSchema(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            return "无法读取版本 \(version) 的 Prompt 数据。"
        }
    }
}
