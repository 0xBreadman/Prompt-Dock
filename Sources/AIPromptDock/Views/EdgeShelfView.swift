import SwiftUI

struct EdgeShelfView: View {
    @EnvironmentObject private var store: PromptStore
    @EnvironmentObject private var settings: DockSettings
    let onHoverChanged: (Bool) -> Void
    let onCopied: () -> Void

    var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().opacity(0.4)
                promptList
                footer
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.7)
        }
        .padding(8)
        .onHover(perform: onHoverChanged)
    }

    private var header: some View {
        HStack(spacing: 10) {
            if let preset = store.activePreset {
                PresetBadgeView(preset: preset, size: 30)
            } else {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(store.activePreset?.name ?? "工作预设")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text("边缘快捷栏")
                    .font(.system(size: 9.5, weight: .medium))
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
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 14)
        .frame(height: 57)
    }

    private var promptList: some View {
        ScrollView {
            LazyVStack(spacing: 7) {
                ForEach(store.promptsInActiveEdgeShelf) { prompt in
                    Button {
                        store.copy(prompt)
                        onCopied()
                    } label: {
                        HStack(spacing: 10) {
                            PromptBadgeView(
                                prompt: prompt,
                                category: store.category(for: prompt),
                                size: 27
                            )

                            Text(prompt.title)
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            Image(systemName: store.copiedPromptID == prompt.id ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(store.copiedPromptID == prompt.id ? Color.green : Color.secondary)
                        }
                        .padding(.horizontal, 11)
                        .frame(minHeight: 46)
                        .contentShape(Rectangle())
                        .background(Color.primary.opacity(0.048), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
        }
    }

    private var footer: some View {
        HStack {
            Circle()
                .fill(Color.accentColor.opacity(0.7))
                .frame(width: 5, height: 5)
            Text(settings.edgeSide == .right ? "离开右侧栏自动收起" : "离开左侧栏自动收起")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(store.promptsInActiveEdgeShelf.count)")
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 33)
        .background(Color.primary.opacity(0.025))
    }
}
