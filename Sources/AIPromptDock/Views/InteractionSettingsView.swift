import SwiftUI

struct InteractionSettingsView: View {
    @EnvironmentObject private var settings: DockSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("高速交互")
                        .font(.title2.bold())
                    Text("为不同速度层级选择呼出方式，不改变 Prompt 正文。")
                        .foregroundStyle(.secondary)
                }

                settingCard(
                    symbol: "circle.hexagongrid.fill",
                    title: "Prompt 转盘",
                    subtitle: "按住快捷键，移动到固定槽位，松开立即复制。"
                ) {
                    HStack {
                        Toggle("启用", isOn: $settings.radialMenuEnabled)
                            .toggleStyle(.switch)
                        Spacer()
                        Button("预览转盘") {
                            NotificationCenter.default.post(name: .previewRadialMenu, object: nil)
                        }
                        .disabled(!settings.radialMenuEnabled)
                    }

                    HStack {
                        Text("转盘快捷键")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $settings.radialShortcut) {
                            ForEach(RadialShortcut.allCases) { shortcut in
                                Text(shortcut.title).tag(shortcut)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 155)
                    }

                    Text("每个工作预设可单独选择 4、6 或 8 个槽位并调整顺序。拖回中心后松开可取消；也可开启短按复制最近使用。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if settings.radialShortcut == .grave {
                        switch settings.radialShortcutRegistrationState {
                        case .registered:
                            Label("单键极速模式已注册：按住 Esc 下方的 ` / · 键呼出，松开即复制。", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        case .needsAccessibility:
                            HStack(spacing: 10) {
                                Label("单键模式需要 macOS 辅助功能权限，才能拦截按键且不输入字符。", systemImage: "hand.raised.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Spacer()
                                Button("开启权限") {
                                    NotificationCenter.default.post(name: .requestAccessibilityPermission, object: nil)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        case .failed(let status):
                            Label("该单键未能注册（系统错误 \(status)）。", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        case .checking:
                            Label("正在检查单键权限…", systemImage: "ellipsis.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                settingCard(
                    symbol: "sidebar.right",
                    title: "屏幕边缘快捷栏",
                    subtitle: "触碰屏幕边缘时出现，点击复制，离开后自动收起。"
                ) {
                    HStack {
                        Toggle("启用", isOn: $settings.edgeShelfEnabled)
                            .toggleStyle(.switch)
                        Spacer()
                        Button("预览侧栏") {
                            NotificationCenter.default.post(name: .previewEdgeShelf, object: nil)
                        }
                        .disabled(!settings.edgeShelfEnabled)
                    }

                    Picker("出现位置", selection: $settings.edgeSide) {
                        ForEach(DockSettings.EdgeSide.allCases) { side in
                            Text(side.title).tag(side)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                settingCard(
                    symbol: "circle.lefthalf.filled",
                    title: "悬浮面板",
                    subtitle: "完整搜索和浏览入口。"
                ) {
                    HStack {
                        Text("面板快捷键")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $settings.dockShortcut) {
                            ForEach(DockShortcut.allCases) { shortcut in
                                Text(shortcut.title).tag(shortcut)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 155)
                    }

                    HStack {
                        Text("窗口透明度")
                        Slider(value: $settings.opacity, in: 0.55...1.0)
                            .frame(maxWidth: 240)
                        Text("\(Int(settings.opacity * 100))%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 38, alignment: .trailing)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
        }
    }

    private func settingCard<Content: View>(
        symbol: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider().opacity(0.55)
            content()
        }
        .padding(18)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.6)
        }
    }
}
