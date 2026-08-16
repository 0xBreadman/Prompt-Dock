import SwiftUI

struct PromptCardView: View {
    let prompt: PromptItem
    let category: PromptCategory?
    let isCopied: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                PromptBadgeView(prompt: prompt, category: category, size: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text(prompt.title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .lineLimit(1)

                    if !prompt.tags.isEmpty {
                        Text(prompt.tags.prefix(3).joined(separator: "  ·  "))
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isCopied ? Color.green : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.primary.opacity(0.055))
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5)
                    }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("复制 \(prompt.title)")
        .help(helpText)
    }

    private var helpText: String {
        guard let badge = ModelBadgeCatalog.badge(id: prompt.primaryModelBadgeID) else {
            return "点击复制完整 Prompt"
        }
        return "点击复制完整 Prompt · 主模型：\(badge.name)"
    }
}
