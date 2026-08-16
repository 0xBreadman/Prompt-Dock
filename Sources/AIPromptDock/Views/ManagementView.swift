import SwiftUI

struct ManagementView: View {
    @EnvironmentObject private var store: PromptStore
    @State private var selectedCategoryID: UUID?
    @State private var selectedPromptID: UUID?
    @State private var selectedPresetID: UUID?
    @State private var deletionRequest: DeletionRequest?

    var body: some View {
        TabView {
            libraryTab
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("Prompt 库", systemImage: "books.vertical.fill") }

            presetsTab
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("工作预设", systemImage: "slider.horizontal.3") }

            InteractionSettingsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("交互方式", systemImage: "cursorarrow.motionlines") }

            LibrarySettingsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("数据与备份", systemImage: "externaldrive.fill") }
        }
        .frame(
            minWidth: 900,
            maxWidth: .infinity,
            minHeight: 600,
            maxHeight: .infinity
        )
        .task {
            if selectedCategoryID == nil { selectedCategoryID = store.sortedCategories.first?.id }
            if selectedPresetID == nil { selectedPresetID = store.sortedPresets.first?.id }
            selectFirstPromptIfNeeded()
        }
        .alert(item: $deletionRequest) { request in
            Alert(
                title: Text(request.title),
                message: Text(request.message),
                primaryButton: .destructive(Text("删除")) { performDeletion(request) },
                secondaryButton: .cancel()
            )
        }
    }

    private var libraryTab: some View {
        HSplitView {
            categoryPane
                .frame(minWidth: 190, idealWidth: 220, maxWidth: 280, maxHeight: .infinity)
            promptPane
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 340, maxHeight: .infinity)

            if let promptID = selectedPromptID, let prompt = store.prompt(id: promptID) {
                PromptEditorView(
                    prompt: prompt,
                    categories: store.sortedCategories,
                    onSave: { updated in
                        store.updatePrompt(updated)
                        selectedCategoryID = updated.categoryID
                        selectedPromptID = updated.id
                    }
                )
                .id(prompt.id)
                .frame(minWidth: 450, maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "选择一个 Prompt",
                    systemImage: "text.quote",
                    description: Text("在左侧选择或新建 Prompt")
                )
                .frame(minWidth: 450, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var categoryPane: some View {
        VStack(spacing: 0) {
            paneHeader("分类")
            List(selection: $selectedCategoryID) {
                ForEach(store.sortedCategories) { category in
                    Label(category.name, systemImage: category.symbolName)
                        .tag(category.id)
                }
            }
            .scrollIndicators(.never)
            .onChange(of: selectedCategoryID) {
                selectFirstPromptIfNeeded()
            }

            if selectedCategoryID != nil {
                TextField("分类名称", text: selectedCategoryNameBinding)
                    .textFieldStyle(.roundedBorder)
                    .padding(8)
            }

            paneToolbar(
                add: {
                    selectedCategoryID = store.addCategory()
                    selectedPromptID = nil
                },
                delete: requestCategoryDeletion,
                canDelete: selectedCategoryID != nil
            )
        }
    }

    private var promptPane: some View {
        VStack(spacing: 0) {
            paneHeader("Prompt")
            List(selection: $selectedPromptID) {
                if let selectedCategoryID {
                    ForEach(store.prompts(in: selectedCategoryID)) { prompt in
                        HStack(spacing: 8) {
                            PromptBadgeView(
                                prompt: prompt,
                                category: store.category(for: prompt),
                                size: 22
                            )
                            Text(prompt.title)
                        }
                        .tag(prompt.id)
                    }
                }
            }
            .scrollIndicators(.never)
            paneToolbar(
                add: addPrompt,
                delete: requestPromptDeletion,
                canDelete: selectedPromptID != nil
            )
        }
    }

    private var presetsTab: some View {
        HSplitView {
            VStack(spacing: 0) {
                paneHeader("工作预设")
                List(selection: $selectedPresetID) {
                    ForEach(store.sortedPresets) { preset in
                        PresetLabelView(preset: preset, badgeSize: 23)
                            .tag(preset.id)
                    }
                }
                paneToolbar(
                    add: { selectedPresetID = store.addPreset() },
                    delete: requestPresetDeletion,
                    canDelete: selectedPresetID != nil && store.sortedPresets.count > 1
                )
            }
            .frame(minWidth: 190, idealWidth: 220, maxWidth: 260)

            if let selectedPresetID {
                PresetEditorView(presetID: selectedPresetID)
                    .frame(minWidth: 520)
            } else {
                ContentUnavailableView("选择一个工作预设", systemImage: "slider.horizontal.3")
                    .frame(minWidth: 520)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func paneHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Color.primary.opacity(0.035))
    }

    private func paneToolbar(
        add: @escaping () -> Void,
        delete: @escaping () -> Void,
        canDelete: Bool
    ) -> some View {
        HStack(spacing: 4) {
            Button(action: add) { Image(systemName: "plus") }
            Button(action: delete) { Image(systemName: "minus") }
                .disabled(!canDelete)
            Spacer()
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Color.primary.opacity(0.025))
    }

    private var selectedCategoryNameBinding: Binding<String> {
        Binding(
            get: {
                guard let selectedCategoryID else { return "" }
                return store.category(id: selectedCategoryID)?.name ?? ""
            },
            set: { value in
                guard let selectedCategoryID,
                      var category = store.category(id: selectedCategoryID) else { return }
                category.name = value
                store.updateCategory(category)
            }
        )
    }

    private func addPrompt() {
        guard let categoryID = selectedCategoryID else { return }
        selectedPromptID = store.addPrompt(to: categoryID)
    }

    private func selectFirstPromptIfNeeded() {
        guard let categoryID = selectedCategoryID else {
            selectedPromptID = nil
            return
        }
        let prompts = store.prompts(in: categoryID)
        if let selectedPromptID,
           prompts.contains(where: { $0.id == selectedPromptID }) {
            return
        }
        selectedPromptID = prompts.first?.id
    }

    private func requestCategoryDeletion() {
        guard let selectedCategoryID,
              let category = store.category(id: selectedCategoryID) else { return }
        deletionRequest = DeletionRequest(
            kind: .category(selectedCategoryID),
            title: "删除“\(category.name)”？",
            message: "这个分类及其中的所有 Prompt 都会被删除。"
        )
    }

    private func requestPromptDeletion() {
        guard let selectedPromptID,
              let prompt = store.prompt(id: selectedPromptID) else { return }
        deletionRequest = DeletionRequest(
            kind: .prompt(selectedPromptID),
            title: "删除“\(prompt.title)”？",
            message: "它也会从所有工作预设中移除。"
        )
    }

    private func requestPresetDeletion() {
        guard let selectedPresetID,
              let preset = store.preset(id: selectedPresetID) else { return }
        deletionRequest = DeletionRequest(
            kind: .preset(selectedPresetID),
            title: "删除预设“\(preset.name)”？",
            message: "Prompt 正文不会被删除。"
        )
    }

    private func performDeletion(_ request: DeletionRequest) {
        switch request.kind {
        case .category(let id):
            store.deleteCategory(id: id)
            selectedCategoryID = store.sortedCategories.first?.id
            selectFirstPromptIfNeeded()
        case .prompt(let id):
            store.deletePrompt(id: id)
            selectedPromptID = nil
            selectFirstPromptIfNeeded()
        case .preset(let id):
            store.deletePreset(id: id)
            selectedPresetID = store.sortedPresets.first?.id
        }
    }
}

private struct DeletionRequest: Identifiable {
    enum Kind {
        case category(UUID)
        case prompt(UUID)
        case preset(UUID)
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let message: String
}
