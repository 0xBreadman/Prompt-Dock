import AppKit
import Combine
import Foundation

@MainActor
final class PromptStore: ObservableObject {
    @Published private(set) var library = PromptLibrary()
    @Published var searchText = ""
    @Published var selectedCategoryID: UUID?
    @Published private(set) var activePresetID: UUID?
    @Published private(set) var copiedPromptID: UUID?
    @Published private(set) var errorMessage: String?
    @Published private(set) var noticeMessage: String?

    private let repository: PromptRepository
    private var copiedResetTask: Task<Void, Never>?

    init(repository: PromptRepository = JSONPromptRepository()) {
        self.repository = repository
        if let value = UserDefaults.standard.string(forKey: "dock.activePresetID") {
            activePresetID = UUID(uuidString: value)
        }
    }

    var sortedCategories: [PromptCategory] {
        library.categories.sorted {
            if $0.sortOrder == $1.sortOrder { return $0.name < $1.name }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var sortedPresets: [DockPreset] {
        library.presets.sorted {
            if $0.sortOrder == $1.sortOrder { return $0.name < $1.name }
            return $0.sortOrder < $1.sortOrder
        }
    }

    var activePreset: DockPreset? {
        library.presets.first { $0.id == activePresetID }
    }

    var categoriesInActivePreset: [PromptCategory] {
        let promptIDs = Set(activePreset?.promptIDs ?? [])
        let categoryIDs = Set(library.prompts.filter { promptIDs.contains($0.id) }.map(\.categoryID))
        return sortedCategories.filter { categoryIDs.contains($0.id) }
    }

    var radialPrompts: [PromptItem] {
        guard let preset = activePreset else { return [] }
        let requestedIDs = preset.quickPromptIDs.isEmpty
            ? Array(preset.promptIDs.prefix(preset.radialSlotCount))
            : preset.quickPromptIDs
        let promptByID = Dictionary(uniqueKeysWithValues: library.prompts.map { ($0.id, $0) })
        return requestedIDs.compactMap { promptByID[$0] }
    }

    /// Prompts shown by compact launch surfaces. This intentionally ignores the
    /// floating panel's temporary category and search filters.
    var promptsInActivePreset: [PromptItem] {
        guard let preset = activePreset else { return [] }
        let promptByID = Dictionary(uniqueKeysWithValues: library.prompts.map { ($0.id, $0) })
        return preset.promptIDs.compactMap { promptByID[$0] }
    }

    var promptsInActiveEdgeShelf: [PromptItem] {
        guard let preset = activePreset else { return [] }
        let promptByID = Dictionary(uniqueKeysWithValues: library.prompts.map { ($0.id, $0) })
        return preset.edgePromptIDs.compactMap { promptByID[$0] }
    }

    var lastUsedPromptInActivePreset: PromptItem? {
        promptsInActivePreset
            .filter { $0.lastUsedAt != nil }
            .max { ($0.lastUsedAt ?? .distantPast) < ($1.lastUsedAt ?? .distantPast) }
    }

    var visiblePrompts: [PromptItem] {
        let presetPromptIDs = Set(activePreset?.promptIDs ?? [])
        return library.prompts
            .filter { prompt in
                let isInPreset = presetPromptIDs.contains(prompt.id)
                let matchesCategory = selectedCategoryID == nil || prompt.categoryID == selectedCategoryID
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let matchesSearch = query.isEmpty
                    || prompt.title.localizedCaseInsensitiveContains(query)
                    || prompt.content.localizedCaseInsensitiveContains(query)
                    || prompt.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                    || modelSearchText(for: prompt).localizedCaseInsensitiveContains(query)
                return isInPreset && matchesCategory && matchesSearch
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder { return $0.title < $1.title }
                return $0.sortOrder < $1.sortOrder
            }
    }

    func load() {
        do {
            library = try repository.load()
            library.schemaVersion = PromptLibrary.currentSchemaVersion
            ensureValidState()
            try repository.save(library)
        } catch {
            errorMessage = error.localizedDescription
            library = .starter
            ensureValidState()
        }
    }

    func activatePreset(_ id: UUID) {
        guard library.presets.contains(where: { $0.id == id }) else { return }
        activePresetID = id
        selectedCategoryID = nil
        UserDefaults.standard.set(id.uuidString, forKey: "dock.activePresetID")
    }

    func copy(_ prompt: PromptItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt.content, forType: .string)

        if let index = library.prompts.firstIndex(where: { $0.id == prompt.id }) {
            library.prompts[index].lastUsedAt = .now
            library.prompts[index].useCount += 1
            persist()
        }

        copiedResetTask?.cancel()
        copiedPromptID = prompt.id
        copiedResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.copiedPromptID = nil
        }
    }

    func category(for prompt: PromptItem) -> PromptCategory? {
        library.categories.first { $0.id == prompt.categoryID }
    }

    func category(id: UUID) -> PromptCategory? {
        library.categories.first { $0.id == id }
    }

    func prompt(id: UUID) -> PromptItem? {
        library.prompts.first { $0.id == id }
    }

    func preset(id: UUID) -> DockPreset? {
        library.presets.first { $0.id == id }
    }

    private func modelSearchText(for prompt: PromptItem) -> String {
        ([prompt.primaryModelBadgeID].compactMap { $0 } + prompt.compatibleModelBadgeIDs)
            .compactMap { ModelBadgeCatalog.badge(id: $0) }
            .flatMap { [$0.id, $0.name] }
            .joined(separator: " ")
    }

    func prompts(in categoryID: UUID) -> [PromptItem] {
        library.prompts
            .filter { $0.categoryID == categoryID }
            .sorted {
                if $0.sortOrder == $1.sortOrder { return $0.title < $1.title }
                return $0.sortOrder < $1.sortOrder
            }
    }

    @discardableResult
    func addCategory() -> UUID {
        let category = PromptCategory(
            name: "新分类",
            symbolName: "folder.fill",
            sortOrder: library.categories.count
        )
        library.categories.append(category)
        persist()
        return category.id
    }

    func updateCategory(_ category: PromptCategory) {
        guard let index = library.categories.firstIndex(where: { $0.id == category.id }) else { return }
        library.categories[index] = category
        persist()
    }

    func deleteCategory(id: UUID) {
        let removedPromptIDs = Set(library.prompts.filter { $0.categoryID == id }.map(\.id))
        library.categories.removeAll { $0.id == id }
        library.prompts.removeAll { $0.categoryID == id }
        for index in library.presets.indices {
            library.presets[index].promptIDs.removeAll { removedPromptIDs.contains($0) }
            library.presets[index].quickPromptIDs.removeAll { removedPromptIDs.contains($0) }
            library.presets[index].edgePromptIDs.removeAll { removedPromptIDs.contains($0) }
        }
        if selectedCategoryID == id { selectedCategoryID = nil }
        persist()
    }

    @discardableResult
    func addPrompt(to categoryID: UUID) -> UUID {
        let prompt = PromptItem(
            title: "新 Prompt",
            content: "",
            categoryID: categoryID,
            sortOrder: prompts(in: categoryID).count
        )
        library.prompts.append(prompt)
        persist()
        return prompt.id
    }

    func updatePrompt(_ prompt: PromptItem) {
        guard let index = library.prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        var updated = prompt
        updated.updatedAt = .now
        library.prompts[index] = updated
        persist()
    }

    func deletePrompt(id: UUID) {
        library.prompts.removeAll { $0.id == id }
        for index in library.presets.indices {
            library.presets[index].promptIDs.removeAll { $0 == id }
            library.presets[index].quickPromptIDs.removeAll { $0 == id }
            library.presets[index].edgePromptIDs.removeAll { $0 == id }
        }
        persist()
    }

    @discardableResult
    func addPreset() -> UUID {
        let preset = DockPreset(
            name: "新工作预设",
            symbolName: "slider.horizontal.3",
            sortOrder: library.presets.count
        )
        library.presets.append(preset)
        persist()
        return preset.id
    }

    func updatePreset(_ preset: DockPreset) {
        guard let index = library.presets.firstIndex(where: { $0.id == preset.id }) else { return }
        var updated = preset
        updated.radialSlotCount = DockPreset.normalizedRadialSlotCount(updated.radialSlotCount)
        updated.quickPromptIDs = Array(updated.quickPromptIDs.prefix(updated.radialSlotCount))
        library.presets[index] = updated
        persist()
    }

    func deletePreset(id: UUID) {
        guard library.presets.count > 1 else { return }
        library.presets.removeAll { $0.id == id }
        if activePresetID == id, let replacement = sortedPresets.first {
            activatePreset(replacement.id)
        }
        persist()
    }

    func setPrompt(_ promptID: UUID, included: Bool, inPreset presetID: UUID) {
        setPrompts([promptID], included: included, inPreset: presetID)
    }

    func setPrompts(_ promptIDs: [UUID], included: Bool, inPreset presetID: UUID) {
        guard let index = library.presets.firstIndex(where: { $0.id == presetID }) else { return }
        if included {
            for promptID in promptIDs where !library.presets[index].promptIDs.contains(promptID) {
                library.presets[index].promptIDs.append(promptID)
            }
        } else {
            let removed = Set(promptIDs)
            library.presets[index].promptIDs.removeAll { removed.contains($0) }
            library.presets[index].quickPromptIDs.removeAll { removed.contains($0) }
            library.presets[index].edgePromptIDs.removeAll { removed.contains($0) }
        }
        persist()
    }

    func toggleQuickPrompt(_ promptID: UUID, inPreset presetID: UUID) {
        guard let index = library.presets.firstIndex(where: { $0.id == presetID }) else { return }
        if let quickIndex = library.presets[index].quickPromptIDs.firstIndex(of: promptID) {
            library.presets[index].quickPromptIDs.remove(at: quickIndex)
        } else {
            guard library.presets[index].quickPromptIDs.count
                    < library.presets[index].radialSlotCount else { return }
            if !library.presets[index].promptIDs.contains(promptID) {
                library.presets[index].promptIDs.append(promptID)
            }
            library.presets[index].quickPromptIDs.append(promptID)
        }
        persist()
    }

    func setEdgePrompt(_ promptID: UUID, included: Bool, inPreset presetID: UUID) {
        guard let index = library.presets.firstIndex(where: { $0.id == presetID }) else { return }
        if included {
            if !library.presets[index].promptIDs.contains(promptID) {
                library.presets[index].promptIDs.append(promptID)
            }
            if !library.presets[index].edgePromptIDs.contains(promptID) {
                library.presets[index].edgePromptIDs.append(promptID)
            }
        } else {
            library.presets[index].edgePromptIDs.removeAll { $0 == promptID }
        }
        persist()
    }

    func moveQuickPrompt(_ promptID: UUID, by offset: Int, inPreset presetID: UUID) {
        guard let presetIndex = library.presets.firstIndex(where: { $0.id == presetID }),
              let sourceIndex = library.presets[presetIndex].quickPromptIDs.firstIndex(of: promptID) else {
            return
        }
        let destinationIndex = sourceIndex + offset
        guard library.presets[presetIndex].quickPromptIDs.indices.contains(destinationIndex) else { return }
        library.presets[presetIndex].quickPromptIDs.swapAt(sourceIndex, destinationIndex)
        persist()
    }

    func clearError() {
        errorMessage = nil
    }

    func clearNotice() {
        noticeMessage = nil
    }

    func showNotice(_ message: String) {
        noticeMessage = message
    }

    func importLibrary(from source: URL) throws {
        let hasAccess = source.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { source.stopAccessingSecurityScopedResource() }
        }

        do {
            library = try repository.importLibrary(from: source)
            library.schemaVersion = PromptLibrary.currentSchemaVersion
            selectedCategoryID = nil
            ensureValidState()
            try repository.save(library)
            noticeMessage = "资料库已导入，共 \(library.prompts.count) 条 Prompt。"
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func exportLibrary(to destination: URL) throws {
        let hasAccess = destination.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { destination.stopAccessingSecurityScopedResource() }
        }

        do {
            try repository.export(library, to: destination)
            noticeMessage = "完整备份已导出。"
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    private func persist() {
        do {
            try repository.save(library)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func ensureValidState() {
        if library.presets.isEmpty {
            library.presets = [
                DockPreset(name: "全部提示词", promptIDs: library.prompts.map(\.id))
            ]
        }
        let validPromptIDs = Set(library.prompts.map(\.id))
        let validBadgeIDs = Set(ModelBadgeCatalog.all.map(\.id))
        for index in library.prompts.indices {
            if let primary = library.prompts[index].primaryModelBadgeID,
               !validBadgeIDs.contains(primary) {
                library.prompts[index].primaryModelBadgeID = nil
            }
            let primary = library.prompts[index].primaryModelBadgeID
            var seenBadges = Set<String>()
            library.prompts[index].compatibleModelBadgeIDs = library.prompts[index].compatibleModelBadgeIDs.filter {
                validBadgeIDs.contains($0) && $0 != primary && seenBadges.insert($0).inserted
            }
        }
        for index in library.presets.indices {
            var seen = Set<UUID>()
            library.presets[index].promptIDs = library.presets[index].promptIDs.filter {
                validPromptIDs.contains($0) && seen.insert($0).inserted
            }
            let visibleIDs = Set(library.presets[index].promptIDs)
            var seenQuick = Set<UUID>()
            library.presets[index].radialSlotCount = DockPreset.normalizedRadialSlotCount(
                library.presets[index].radialSlotCount
            )
            library.presets[index].quickPromptIDs = Array(
                library.presets[index].quickPromptIDs.filter {
                    visibleIDs.contains($0) && seenQuick.insert($0).inserted
                }.prefix(library.presets[index].radialSlotCount)
            )
            var seenEdge = Set<UUID>()
            library.presets[index].edgePromptIDs = library.presets[index].edgePromptIDs.filter {
                visibleIDs.contains($0) && seenEdge.insert($0).inserted
            }
        }
        if let activePresetID,
           library.presets.contains(where: { $0.id == activePresetID }) {
            return
        }
        if let first = sortedPresets.first {
            activatePreset(first.id)
        }
    }
}
