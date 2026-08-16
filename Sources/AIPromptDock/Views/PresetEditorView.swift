import SwiftUI

struct PresetEditorView: View {
    @EnvironmentObject private var store: PromptStore
    let presetID: UUID

    @State private var surface: Surface = .panel

    private enum Surface: String, CaseIterable, Identifiable {
        case panel = "悬浮面板"
        case radial = "快捷转盘"
        case edge = "侧边栏"

        var id: Self { self }

        var symbol: String {
            switch self {
            case .panel: "rectangle.grid.1x2"
            case .radial: "circle.hexagongrid.fill"
            case .edge: "sidebar.right"
            }
        }
    }

    private let symbols = [
        "square.grid.2x2", "sparkles", "photo.on.rectangle.angled",
        "video.fill", "bag.fill", "megaphone.fill", "wand.and.stars"
    ]

    var body: some View {
        if let preset = store.preset(id: presetID) {
            VStack(alignment: .leading, spacing: 0) {
                header(preset)
                Divider().opacity(0.5)

                Picker("配置区域", selection: $surface) {
                    ForEach(Surface.allCases) { item in
                        Label(item.rawValue, systemImage: item.symbol).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                Group {
                    switch surface {
                    case .panel:
                        panelConfiguration(preset)
                    case .radial:
                        radialConfiguration(preset)
                    case .edge:
                        edgeConfiguration(preset)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func header(_ preset: DockPreset) -> some View {
        HStack(spacing: 14) {
            PresetBadgeView(preset: preset, size: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text("工作预设")
                    .font(.title2.bold())
                TextField("预设名称", text: presetNameBinding)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .frame(maxWidth: 260)
            }

            Picker("图标", selection: presetSymbolBinding) {
                ForEach(symbols, id: \.self) { symbol in
                    Image(systemName: symbol).tag(symbol)
                }
            }
            .labelsHidden()
            .frame(width: 72)

            Spacer()

            HStack(spacing: 16) {
                metric(value: preset.promptIDs.count, label: "面板")
                metric(value: preset.quickPromptIDs.count, label: "转盘")
                metric(value: preset.edgePromptIDs.count, label: "侧栏")
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 82)
    }

    private func metric(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 40)
    }

    private func panelConfiguration(_ preset: DockPreset) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionIntro(
                title: "选择这个工作阶段需要的 Prompt",
                detail: "这里是预设的内容总集；转盘和侧边栏只能从中挑选。"
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(store.sortedCategories) { category in
                        let prompts = store.prompts(in: category.id)
                        if !prompts.isEmpty {
                            categoryCard(category, prompts: prompts, preset: preset)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.never)
        }
    }

    private func radialConfiguration(_ preset: DockPreset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("转盘槽位")
                        .font(.headline)
                    Text("按住快捷键移动选择，松开立即复制。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("槽位数量", selection: radialSlotCountBinding) {
                    ForEach(DockPreset.supportedRadialSlotCounts, id: \.self) { count in
                        Text("\(count) 个").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            Toggle("短按快捷键时，直接复制这个预设里最近使用的 Prompt", isOn: quickTapBinding)
                .toggleStyle(.switch)

            Divider().opacity(0.45)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已固定槽位")
                            .font(.headline)

                        if preset.quickPromptIDs.isEmpty {
                            emptyConfiguration(
                                "尚未固定槽位",
                                detail: "转盘将暂时使用面板中的前 \(preset.radialSlotCount) 条 Prompt。"
                            )
                        } else {
                            ForEach(Array(preset.quickPromptIDs.enumerated()), id: \.element) { index, promptID in
                                if let prompt = store.prompt(id: promptID) {
                                    radialSlotRow(prompt, index: index, total: preset.quickPromptIDs.count)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("可加入转盘")
                            .font(.headline)

                        ForEach(availableRadialPrompts(preset)) { prompt in
                            compactPromptRow(prompt) {
                                store.toggleQuickPrompt(prompt.id, inPreset: presetID)
                            }
                            .disabled(preset.quickPromptIDs.count >= preset.radialSlotCount)
                        }
                    }
                }
                .padding(.bottom, 18)
            }
            .scrollIndicators(.never)
        }
        .padding(.horizontal, 20)
    }

    private func edgeConfiguration(_ preset: DockPreset) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionIntro(
                title: "选择侧边栏显示内容",
                detail: "只保留需要一碰即用的 Prompt，避免侧栏出现滚动拥挤。"
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(promptsInPreset(preset)) { prompt in
                        HStack(spacing: 10) {
                            PromptBadgeView(
                                prompt: prompt,
                                category: store.category(for: prompt),
                                size: 25
                            )
                            Toggle(prompt.title, isOn: edgeInclusionBinding(prompt.id))
                                .toggleStyle(.checkbox)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 11))
                    }

                    if preset.promptIDs.isEmpty {
                        emptyConfiguration("面板中还没有 Prompt", detail: "先到“悬浮面板”页选择内容。")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.never)
        }
    }

    private func categoryCard(
        _ category: PromptCategory,
        prompts: [PromptItem],
        preset: DockPreset
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(category.name, systemImage: category.symbolName)
                    .font(.headline)
                Spacer()
                Button("全选") {
                    store.setPrompts(prompts.map(\.id), included: true, inPreset: presetID)
                }
                Button("清空") {
                    store.setPrompts(prompts.map(\.id), included: false, inPreset: presetID)
                }
            }
            .buttonStyle(.plain)
            .font(.caption)

            ForEach(prompts) { prompt in
                HStack(spacing: 10) {
                    PromptBadgeView(prompt: prompt, category: category, size: 24)
                    Toggle(prompt.title, isOn: panelInclusionBinding(prompt.id))
                        .toggleStyle(.checkbox)
                    Spacer()

                    let isQuick = preset.quickPromptIDs.contains(prompt.id)
                    let isEdge = preset.edgePromptIDs.contains(prompt.id)
                    if isQuick || isEdge {
                        HStack(spacing: 5) {
                            if isQuick { Image(systemName: "circle.hexagongrid.fill") }
                            if isEdge { Image(systemName: "sidebar.right") }
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.6)
        }
    }

    private func radialSlotRow(_ prompt: PromptItem, index: Int, total: Int) -> some View {
        HStack(spacing: 11) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(Color.accentColor, in: Circle())

            PromptBadgeView(prompt: prompt, category: store.category(for: prompt), size: 27)
            Text(prompt.title)
                .font(.system(size: 12.5, weight: .semibold))
                .lineLimit(1)
            Spacer()

            Button {
                store.moveQuickPrompt(prompt.id, by: -1, inPreset: presetID)
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(index == 0)

            Button {
                store.moveQuickPrompt(prompt.id, by: 1, inPreset: presetID)
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(index == total - 1)

            Button {
                store.toggleQuickPrompt(prompt.id, inPreset: presetID)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 11)
        .frame(minHeight: 46)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 11))
    }

    private func compactPromptRow(_ prompt: PromptItem, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            PromptBadgeView(prompt: prompt, category: store.category(for: prompt), size: 25)
            Text(prompt.title)
                .font(.system(size: 12.5, weight: .medium))
                .lineLimit(1)
            Spacer()
            Button(action: action) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 11)
        .frame(minHeight: 42)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
    }

    private func sectionIntro(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 3)
    }

    private func emptyConfiguration(_ title: String, detail: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: "square.dashed")
                .font(.title3)
                .foregroundStyle(.tertiary)
            Text(title).font(.callout.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
    }

    private func promptsInPreset(_ preset: DockPreset) -> [PromptItem] {
        preset.promptIDs.compactMap { store.prompt(id: $0) }
    }

    private func availableRadialPrompts(_ preset: DockPreset) -> [PromptItem] {
        let quickIDs = Set(preset.quickPromptIDs)
        return promptsInPreset(preset).filter { !quickIDs.contains($0.id) }
    }

    private var presetNameBinding: Binding<String> {
        Binding(
            get: { store.preset(id: presetID)?.name ?? "" },
            set: { value in
                guard var preset = store.preset(id: presetID) else { return }
                preset.name = value
                store.updatePreset(preset)
            }
        )
    }

    private var presetSymbolBinding: Binding<String> {
        Binding(
            get: { store.preset(id: presetID)?.symbolName ?? "square.grid.2x2" },
            set: { value in
                guard var preset = store.preset(id: presetID) else { return }
                preset.symbolName = value
                store.updatePreset(preset)
            }
        )
    }

    private var radialSlotCountBinding: Binding<Int> {
        Binding(
            get: { store.preset(id: presetID)?.radialSlotCount ?? 6 },
            set: { value in
                guard var preset = store.preset(id: presetID) else { return }
                preset.radialSlotCount = value
                store.updatePreset(preset)
            }
        )
    }

    private var quickTapBinding: Binding<Bool> {
        Binding(
            get: { store.preset(id: presetID)?.copiesLastPromptOnQuickTap ?? true },
            set: { value in
                guard var preset = store.preset(id: presetID) else { return }
                preset.copiesLastPromptOnQuickTap = value
                store.updatePreset(preset)
            }
        )
    }

    private func panelInclusionBinding(_ promptID: UUID) -> Binding<Bool> {
        Binding(
            get: { store.preset(id: presetID)?.promptIDs.contains(promptID) == true },
            set: { included in
                store.setPrompt(promptID, included: included, inPreset: presetID)
            }
        )
    }

    private func edgeInclusionBinding(_ promptID: UUID) -> Binding<Bool> {
        Binding(
            get: { store.preset(id: presetID)?.edgePromptIDs.contains(promptID) == true },
            set: { included in
                store.setEdgePrompt(promptID, included: included, inPreset: presetID)
            }
        )
    }
}
