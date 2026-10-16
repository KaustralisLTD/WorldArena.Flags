import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Напоминание от друга (вместо системного `alert`).
struct FriendNudgePopupView: View {
    let fromUsername: String
    let phraseKey: String
    let onContinue: () -> Void

    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var popupCardFill: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }

    private var phrase: String {
        localizationManager.localizedString(phraseKey)
    }

    private var title: String {
        let template = localizationManager.localizedString("%@ reminds you")
        if template == "%@ reminds you" {
            return "\(fromUsername) reminds you"
        }
        return String(format: template, fromUsername)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.62 : 0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.25, blue: 0.95),
                            Color(red: 0.12, green: 0.55, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    VStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                        Text(title)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text(phrase)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onContinue) {
                        Text(localizationManager.localizedString("CONTINUE"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.45, blue: 1),
                                        Color(red: 0.55, green: 0.3, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.blue.opacity(0.35), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(popupCardFill)
                )
                .offset(y: -18)
            }
            .padding(.horizontal, 22)
            .shadow(color: .black.opacity(0.25), radius: 30, y: 18)
        }
    }
}
