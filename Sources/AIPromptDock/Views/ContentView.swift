import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PromptStore
    @EnvironmentObject private var settings: DockSettings
    @State private var showsOpacity = false

    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                categoryStrip
                Divider().opacity(0.45)
                promptList
                footer
            }
        }
        .frame(minWidth: 300, idealWidth: 350, minHeight: 390, idealHeight: 620)
        .alert("无法保存 Prompt", isPresented: errorBinding) {
            Button("好") { store.clearError() }
        } message: {
            Text(store.errorMessage ?? "未知错误")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prompt Dock")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("点一下，复制完整 Prompt")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    ForEach(store.sortedPresets) { preset in
                        Button {
                            store.activatePreset(preset.id)
                        } label: {
                            PresetLabelView(preset: preset, badgeSize: 18)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        if let preset = store.activePreset {
                            PresetBadgeView(preset: preset, size: 18)
                            Text(preset.name)
                                .lineLimit(1)
                        } else {
                            Image(systemName: "square.grid.2x2")
                            Text("选择预设")
                        }
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 9)
                    .frame(height: 27)
                    .background(Color.primary.opacity(0.07), in: Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button {
                    NotificationCenter.default.post(name: .openPromptManager, object: nil)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("管理 Prompt 与工作预设")

                Button {
                    showsOpacity.toggle()
                } label: {
                    Image(systemName: "circle.lefthalf.filled")
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .popover(isPresented: $showsOpacity, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("窗口透明度")
                            .font(.headline)
                        Slider(value: $settings.opacity, in: 0.55...1.0)
                            .frame(width: 170)
                    }
                    .padding(14)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索标题、内容或标签", text: $store.searchText)
                    .textFieldStyle(.plain)
                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 34)
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 12)
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                categoryButton(title: "全部", symbol: "square.grid.2x2", id: nil)
                ForEach(store.categoriesInActivePreset) { category in
                    categoryButton(title: category.name, symbol: category.symbolName, id: category.id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 11)
        }
    }

    private var promptList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if store.visiblePrompts.isEmpty {
                    ContentUnavailableView(
                        "没有匹配的 Prompt",
                        systemImage: "text.magnifyingglass",
                        description: Text("换个关键词或分类试试")
                    )
                    .frame(minHeight: 260)
                } else {
                    ForEach(store.visiblePrompts) { prompt in
                        PromptCardView(
                            prompt: prompt,
                            category: store.category(for: prompt),
                            isCopied: store.copiedPromptID == prompt.id
                        ) {
                            store.copy(prompt)
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: store.copiedPromptID == nil ? "command" : "checkmark.circle.fill")
                .foregroundStyle(store.copiedPromptID == nil ? Color.secondary : Color.green)
            Text(
                store.copiedPromptID == nil
                    ? "按住 \(settings.radialShortcut.compactTitle) 转盘  ·  \(settings.dockShortcut.title) 面板"
                    : "已复制到剪贴板"
            )
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(store.copiedPromptID == nil ? Color.secondary : Color.primary)
            Spacer()
            Text("\(store.visiblePrompts.count) prompts")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .frame(height: 34)
        .background(Color.primary.opacity(0.025))
        .animation(.easeOut(duration: 0.2), value: store.copiedPromptID)
    }

    private func categoryButton(title: String, symbol: String, id: UUID?) -> some View {
        let selected = store.selectedCategoryID == id
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                store.selectedCategoryID = id
            }
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 11.5, weight: .medium))
                .padding(.horizontal, 10)
                .frame(height: 29)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background(
                    selected ? Color.accentColor : Color.primary.opacity(0.055),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )
    }
}
