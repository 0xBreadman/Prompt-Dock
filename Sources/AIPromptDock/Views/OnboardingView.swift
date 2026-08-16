import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: DockSettings
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 42, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
                Text("欢迎使用 Prompt Dock")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("把完整 Prompt 留在本机，在需要时用最短路径取出。")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 24)

            HStack(spacing: 12) {
                featureCard("square.grid.2x2.fill", "工作预设", "只显示当前工作阶段需要的 Prompt")
                featureCard("circle.hexagongrid.fill", "按键转盘", "按住、移动、松开，直接完成复制")
                featureCard("sidebar.right", "边缘快捷栏", "触碰屏幕边缘即可快速展开")
            }
            .padding(.horizontal, 26)

            VStack(spacing: 13) {
                shortcutRow("呼出悬浮面板", selection: $settings.dockShortcut)
                radialShortcutRow
            }
            .padding(18)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 26)
            .padding(.top, 18)

            Spacer()

            HStack {
                Label("Prompt 默认只保存在这台 Mac", systemImage: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("开始使用") {
                    settings.hasCompletedOnboarding = true
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(26)
        }
        .frame(width: 650, height: 520)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
    }

    private func featureCard(_ symbol: String, _ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.11), in: Circle())
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.7)
        }
    }

    private func shortcutRow(_ title: String, selection: Binding<DockShortcut>) -> some View {
        HStack {
            Text(title).font(.callout.weight(.medium))
            Spacer()
            Picker("", selection: selection) {
                ForEach(DockShortcut.allCases) { shortcut in
                    Text(shortcut.title).tag(shortcut)
                }
            }
            .labelsHidden()
            .frame(width: 165)
        }
    }

    private var radialShortcutRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("呼出按键转盘").font(.callout.weight(.medium))
                Text(settings.radialShortcut == .grave
                     ? "单键极速模式，· 将专用于转盘"
                     : "组合键不会影响正常文字输入")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("", selection: $settings.radialShortcut) {
                ForEach(RadialShortcut.allCases) { shortcut in
                    Text(shortcut.title).tag(shortcut)
                }
            }
            .labelsHidden()
            .frame(width: 165)
        }
    }
}
