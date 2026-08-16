import SwiftUI

struct ModelBadgeView: View {
    let badge: ModelBadge
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.273, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.17, blue: 0.18),
                            Color(red: 0.04, green: 0.045, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: size * 0.075) {
                Text(badge.id)
                    .font(
                        .system(
                            size: size * (badge.id.count == 2 ? 0.30 : 0.25),
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .tracking(-size * 0.014)
                    .foregroundStyle(Color(white: 0.97))
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                Capsule()
                    .fill(badge.accent)
                    .frame(width: size * 0.29, height: max(1.5, size * 0.032))
            }
            .offset(y: size * 0.035)
            .padding(.horizontal, size * 0.1)
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.273, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: max(0.5, size / 85))
        }
        .shadow(color: .black.opacity(size >= 36 ? 0.16 : 0.08), radius: size * 0.1, y: size * 0.045)
        .accessibilityLabel(badge.name)
    }
}

struct PresetBadgeView: View {
    let preset: DockPreset
    var size: CGFloat = 24

    var body: some View {
        Image(systemName: preset.symbolName)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: size * 0.3))
    }
}

struct PromptBadgeView: View {
    let prompt: PromptItem
    let category: PromptCategory?
    var size: CGFloat = 30
    var fallbackForeground: Color = .accentColor

    var body: some View {
        if let badge = ModelBadgeCatalog.badge(id: prompt.primaryModelBadgeID) {
            ModelBadgeView(badge: badge, size: size)
        } else {
            Image(systemName: category?.symbolName ?? "text.quote")
                .font(.system(size: size * 0.47, weight: .semibold))
                .foregroundStyle(fallbackForeground)
                .frame(width: size, height: size)
                .background(fallbackForeground.opacity(0.11), in: RoundedRectangle(cornerRadius: size * 0.3))
        }
    }
}

struct PresetLabelView: View {
    let preset: DockPreset
    var badgeSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 8) {
            PresetBadgeView(preset: preset, size: badgeSize)
            Text(preset.name)
                .lineLimit(1)
        }
    }
}
