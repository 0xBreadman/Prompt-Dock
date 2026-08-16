import Foundation

struct JSONPromptRepository: PromptRepository {
    private let fileManager: FileManager
    let libraryURL: URL

    init(fileManager: FileManager = .default, libraryURL: URL? = nil) {
        self.fileManager = fileManager

        if let libraryURL {
            self.libraryURL = libraryURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.libraryURL = appSupport
                .appendingPathComponent("AIPromptDock", isDirectory: true)
                .appendingPathComponent("library.json", isDirectory: false)
        }
    }

    func load() throws -> PromptLibrary {
        guard fileManager.fileExists(atPath: libraryURL.path) else {
            return .starter
        }

        let data = try Data(contentsOf: libraryURL)
        let library = try Self.decoder.decode(PromptLibrary.self, from: data)
        guard library.schemaVersion <= PromptLibrary.currentSchemaVersion else {
            throw PromptRepositoryError.unsupportedSchema(library.schemaVersion)
        }
        return library
    }

    func save(_ library: PromptLibrary) throws {
        try ensureParentDirectory(for: libraryURL)
        try createDailyBackupIfNeeded()
        let data = try Self.encoder.encode(library)
        try data.write(to: libraryURL, options: [.atomic])
    }

    func export(_ library: PromptLibrary, to destination: URL) throws {
        try ensureParentDirectory(for: destination)
        let data = try Self.encoder.encode(library)
        try data.write(to: destination, options: [.atomic])
    }

    func importLibrary(from source: URL) throws -> PromptLibrary {
        let data = try Data(contentsOf: source)
        let library = try Self.decoder.decode(PromptLibrary.self, from: data)
        guard library.schemaVersion <= PromptLibrary.currentSchemaVersion else {
            throw PromptRepositoryError.unsupportedSchema(library.schemaVersion)
        }
        return library
    }

    private func ensureParentDirectory(for url: URL) throws {
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func createDailyBackupIfNeeded() throws {
        guard fileManager.fileExists(atPath: libraryURL.path) else { return }
        let backupDirectory = libraryURL.deletingLastPathComponent()
            .appendingPathComponent("Backups", isDirectory: true)
        try fileManager.createDirectory(
            at: backupDirectory,
            withIntermediateDirectories: true
        )

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let backupURL = backupDirectory
            .appendingPathComponent("library-\(formatter.string(from: .now)).json")
        guard !fileManager.fileExists(atPath: backupURL.path) else { return }
        try fileManager.copyItem(at: libraryURL, to: backupURL)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
