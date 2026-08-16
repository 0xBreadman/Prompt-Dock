import SwiftUI

struct RadialMenuView: View {
    @ObservedObject var state: RadialMenuState

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius: CGFloat = 145

            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 304, height: 304)
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.22), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 28, y: 14)

                Circle()
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    .frame(width: 226, height: 226)

                ForEach(Array(state.prompts.enumerated()), id: \.element.id) { index, prompt in
                    let angle = Angle.degrees(-90 + Double(index) * 360 / Double(state.prompts.count))
                    radialItem(prompt: prompt, index: index)
                        .position(
                            x: center.x + cos(angle.radians) * radius,
                            y: center.y + sin(angle.radians) * radius
                        )
                }

                centerControl
                    .position(center)
            }
        }
        .frame(width: 430, height: 430)
    }

    private var centerControl: some View {
        VStack(spacing: 5) {
            if let prompt = state.selectedPrompt {
                PromptBadgeView(
                    prompt: prompt,
                    category: state.categories[prompt.categoryID],
                    size: 30,
                    fallbackForeground: .white
                )
                Text(prompt.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            } else {
                Text("·")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                Text(state.quickTapPrompt == nil ? "移动选择" : "移动选择 · 短按最近")
                    .font(.system(size: 10.5, weight: .medium))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(state.selectedPrompt == nil ? Color.primary : Color.white)
        .frame(width: 96, height: 96)
        .background(
            state.selectedPrompt == nil ? Color.primary.opacity(0.065) : Color.accentColor,
            in: Circle()
        )
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(state.selectedPrompt == nil ? 0.18 : 0.32), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
        .animation(.easeOut(duration: 0.14), value: state.selectedIndex)
    }

    private func radialItem(prompt: PromptItem, index: Int) -> some View {
        let isSelected = state.selectedIndex == index
        let category = state.categories[prompt.categoryID]

        return VStack(spacing: 5) {
            HStack(spacing: 5) {
                PromptBadgeView(
                    prompt: prompt,
                    category: category,
                    size: 20,
                    fallbackForeground: isSelected ? .white : .accentColor
                )
                Text("\(index + 1)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .opacity(0.62)
            }
            Text(prompt.title)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .frame(width: 112, height: 62)
        .background(
            isSelected ? Color.accentColor : Color(nsColor: .windowBackgroundColor).opacity(0.9),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(isSelected ? 0.3 : 0.18), lineWidth: 0.7)
        }
        .shadow(color: .black.opacity(isSelected ? 0.2 : 0.11), radius: isSelected ? 13 : 8, y: 5)
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}
