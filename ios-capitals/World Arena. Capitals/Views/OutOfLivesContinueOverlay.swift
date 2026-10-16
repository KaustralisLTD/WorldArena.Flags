import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

/// Полноэкранный оверлей вместо алерта «жизни закончились»: один явный сценарий продолжения (реклама), вторичные выходы, мягкие заголовки.
struct OutOfLivesContinueOverlay: View {
    @ObservedObject private var localization = LocalizationManager.shared

    let headlineVariant: Int
    let livesRewardAmount: Int
    let rewardedAdEnabled: Bool
    let onContinuePrimary: () -> Void
    let onPlayAgain: () -> Void
    let onExit: () -> Void
    let onPremiumFooter: () -> Void

    @State private var showUrgency = false
    @State private var pulsePrimary = false

    private var headlineKey: String {
        let idx = (headlineVariant % 7) + 1
        return "Out of lives headline \(idx)"
    }

    private var primaryTitle: String {
        if rewardedAdEnabled {
            return String(
                format: localization.localizedString("Continue with bonus lives"),
                locale: localization.currentLocale,
                livesRewardAmount
            )
        }
        return localization.localizedString("Out of lives continue premium")
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.48))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(alignment: .leading, spacing: 14) {
                    Text(localization.localizedString(headlineKey))
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(localization.localizedString("Out of lives continue subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.78))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if showUrgency {
                        Text(localization.localizedString("Out of lives urgency"))
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.orange)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(
                            String(
                                format: localization.localizedString("Out of lives perk resume"),
                                locale: localization.currentLocale,
                                livesRewardAmount
                            )
                        )
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.72))
                        Text(localization.localizedString("Out of lives perk progress"))
                            .font(.caption)
                            .foregroundColor(.primary.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: onContinuePrimary) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                            Text(primaryTitle)
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red.opacity(0.92)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.orange.opacity(0.35), radius: pulsePrimary ? 14 : 8, x: 0, y: pulsePrimary ? 8 : 5)
                        .scaleEffect(pulsePrimary ? 1.04 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                    .animation(
                        .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                        value: pulsePrimary
                    )

                    HStack(spacing: 20) {
                        Button(action: onPlayAgain) {
                            Text(localization.localizedString("Play Again"))
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button(action: onExit) {
                            Text(localization.localizedString("Exit"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                    Button(action: onPremiumFooter) {
                        Text(localization.localizedString("Ad-free with Premium"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(22)
                .frame(maxWidth: 400)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        #if os(iOS)
                        .fill(Color(UIColor.systemBackground))
                        #else
                        .fill(Color(NSColor.windowBackgroundColor))
                        #endif
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 24)
            }
        }
        .onAppear {
            showUrgency = false
            pulsePrimary = false
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeOut(duration: 0.25)) {
                    showUrgency = true
                }
                pulsePrimary = true
            }
        }
    }
}
