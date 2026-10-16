import SwiftUI

/// Полноэкранный анимированный экран при разблокировке континента (продающий UX).
struct ContinentMasterBadgeView: View {
    let continentTitle: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var showButton = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.5),
                                    Color.mint.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(glowOpacity)

                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(scale)
                }

                Text("\(continentTitle) Master")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)

                Text(LocalizationManager.shared.localizedString("Continent mastered! Keep going."))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(opacity)

                if showButton {
                    Button(action: onDismiss) {
                        Text(LocalizationManager.shared.localizedString("CONTINUE"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.green)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8)) {
                glowOpacity = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showButton = true
                }
            }
        }
    }
}

#Preview {
    ContinentMasterBadgeView(continentTitle: "Asia", onDismiss: {})
}
