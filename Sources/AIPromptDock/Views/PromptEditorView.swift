import SwiftUI

struct PromptEditorView: View {
    let prompt: PromptItem
    let categories: [PromptCategory]
    let onSave: (PromptItem) -> Void

    @State private var draft: PromptItem
    @State private var showsModelPicker = false

    init(
        prompt: PromptItem,
        categories: [PromptCategory],
        onSave: @escaping (PromptItem) -> Void
    ) {
        self.prompt = prompt
        self.categories = categories
        self.onSave = onSave
        _draft = State(initialValue: prompt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("编辑 Prompt")
                        .font(.title2.bold())
                    Text("正文编辑区会随窗口自动扩展")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("保存") {
                    onSave(draft)
                }
                .keyboardShortcut("s", modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 22)
            .frame(height: 68)

            Divider().opacity(0.55)

            VStack(alignment: .leading, spacing: 18) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow {
                        fieldLabel("标题")
                        TextField("Prompt 标题", text: $draft.title)
                            .textFieldStyle(.roundedBorder)
                    }

                    GridRow {
                        fieldLabel("分类")
                        Picker("", selection: $draft.categoryID) {
                            ForEach(categories) { category in
                                Label(category.name, systemImage: category.symbolName)
                                    .tag(category.id)
                            }
                        }
                        .labelsHidden()
                    }

                    GridRow {
                        fieldLabel("标签")
                        TextField("ugc, video, shopify", text: tagsBinding)
                            .textFieldStyle(.roundedBorder)
                    }

                    GridRow {
                        fieldLabel("模型")
                        modelSelectionButton
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("完整 Prompt")
                            .font(.headline)
                        Spacer()
                        Text("\(draft.content.count) 字符")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                    TextEditor(text: $draft.content)
                        .font(.system(.body, design: .rounded))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.7)
                        }
                        .frame(minHeight: 360, maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showsModelPicker) {
            PromptModelPickerView(
                primarySelection: $draft.primaryModelBadgeID,
                compatibleSelections: $draft.compatibleModelBadgeIDs
            )
        }
    }

    private var modelSelectionButton: some View {
        Button {
            showsModelPicker = true
        } label: {
            HStack(spacing: 11) {
                PromptBadgeView(
                    prompt: draft,
                    category: categories.first { $0.id == draft.categoryID },
                    size: 34
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(primaryBadge?.name ?? "通用 Prompt")
                        .font(.system(size: 12.5, weight: .semibold))
                    Text(modelSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: -3) {
                    ForEach(compatibleBadges.prefix(4)) { badge in
                        ModelBadgeView(badge: badge, size: 23)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5)
                            }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 48)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.6)
            }
        }
        .buttonStyle(.plain)
        .help("选择主模型和兼容模型")
    }

    private var primaryBadge: ModelBadge? {
        ModelBadgeCatalog.badge(id: draft.primaryModelBadgeID)
    }

    private var compatibleBadges: [ModelBadge] {
        draft.compatibleModelBadgeIDs.compactMap { ModelBadgeCatalog.badge(id: $0) }
    }

    private var modelSummary: String {
        if compatibleBadges.isEmpty {
            return primaryBadge == nil ? "未绑定具体模型，日常显示分类图标" : "仅主模型"
        }
        let names = compatibleBadges.map(\.name).joined(separator: "、")
        return "另兼容 \(names)"
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 42, alignment: .leading)
    }

    private var tagsBinding: Binding<String> {
        Binding(
            get: { draft.tags.joined(separator: ", ") },
            set: { value in
                draft.tags = value
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        )
    }
}
