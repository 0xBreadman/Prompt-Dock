import SwiftUI

struct PromptModelPickerView: View {
    @Binding var primarySelection: String?
    @Binding var compatibleSelections: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var mode: SelectionMode = .primary
    @State private var searchText = ""

    private enum SelectionMode: String, CaseIterable, Identifiable {
        case primary = "主模型"
        case compatible = "兼容模型"

        var id: Self { self }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 172, maximum: 210), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)
            modelGrid
        }
        .frame(minWidth: 720, idealWidth: 760, minHeight: 590, idealHeight: 650)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: primarySelection) {
            compatibleSelections.removeAll { $0 == primarySelection }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("选择适用模型")
                        .font(.title2.bold())
                    Text("主模型用于日常显示；兼容模型保留适配信息，但不会让卡片变得拥挤。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }

            Picker("选择类型", selection: $mode) {
                ForEach(SelectionMode.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索模型名称或缩写", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 36)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
    }

    private var modelGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                if mode == .primary {
                    genericOption
                } else {
                    HStack {
                        Label("已选择 \(compatibleSelections.count) 个兼容模型", systemImage: "checkmark.circle")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !compatibleSelections.isEmpty {
                            Button("清空") { compatibleSelections = [] }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(ModelBadgeGroup.allCases) { group in
                    let badges = matchingBadges(in: group)
                    if !badges.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.rawValue)
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                                ForEach(badges) { badge in
                                    badgeButton(badge)
                                }
                            }
                        }
                    }
                }

                if matchingBadgeCount == 0 {
                    ContentUnavailableView.search(text: searchText)
                        .frame(maxWidth: .infinity, minHeight: 220)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.never)
    }

    private var genericOption: some View {
        Button {
            primarySelection = nil
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 42, height: 42)
                    .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("通用 Prompt")
                        .font(.system(size: 13, weight: .semibold))
                    Text("显示所属分类图标")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if primarySelection == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(10)
            .frame(maxWidth: 260)
            .background(primarySelection == nil ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(primarySelection == nil ? Color.accentColor.opacity(0.42) : Color.primary.opacity(0.07), lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
    }

    private func badgeButton(_ badge: ModelBadge) -> some View {
        let isPrimary = primarySelection == badge.id
        let isCompatible = compatibleSelections.contains(badge.id)
        let isSelected = mode == .primary ? isPrimary : isCompatible

        return Button {
            switch mode {
            case .primary:
                primarySelection = badge.id
            case .compatible:
                guard !isPrimary else { return }
                if isCompatible {
                    compatibleSelections.removeAll { $0 == badge.id }
                } else {
                    compatibleSelections.append(badge.id)
                }
            }
        } label: {
            HStack(spacing: 10) {
                ModelBadgeView(badge: badge, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(badge.name)
                        .font(.system(size: 12.5, weight: .semibold))
                        .lineLimit(1)
                    Text(isPrimary && mode == .compatible ? "当前主模型" : badge.id)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(isPrimary && mode == .compatible ? Color.secondary : badge.accent)
                }
                Spacer(minLength: 2)
                if isSelected {
                    Image(systemName: mode == .primary ? "checkmark.circle.fill" : "checkmark.square.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.42) : Color.primary.opacity(0.07), lineWidth: 0.8)
            }
            .opacity(mode == .compatible && isPrimary ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .disabled(mode == .compatible && isPrimary)
    }

    private var normalizedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matchingBadgeCount: Int {
        ModelBadgeGroup.allCases.reduce(0) { $0 + matchingBadges(in: $1).count }
    }

    private func matchingBadges(in group: ModelBadgeGroup) -> [ModelBadge] {
        let badges = ModelBadgeCatalog.badges(in: group)
        guard !normalizedSearch.isEmpty else { return badges }
        return badges.filter {
            $0.name.localizedCaseInsensitiveContains(normalizedSearch)
                || $0.id.localizedCaseInsensitiveContains(normalizedSearch)
        }
    }
}
