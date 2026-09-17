import SwiftUI

// MARK: - Hero

struct LearningCountryHeroView: View {
    let countryCode: String
    let countryName: String
    let flagEmoji: String
    let regionName: String
    let isLearned: Bool
    let isFavorite: Bool
    let isDifficult: Bool
    let canGoPrevious: Bool
    let canGoNext: Bool
    let onBack: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToggleFavorite: () -> Void
    let onToggleDifficult: () -> Void

    @ObservedObject private var localizationManager = LocalizationManager.shared
    private var headerStyle: CountryHeaderStyle {
        CountryHeaderStyles.getHeaderStyle(for: countryCode)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                heroBackground
                Color.black.opacity(0.28)
                    .allowsHitTesting(false)
                VStack(spacing: 0) {
                    topBar(safeTop: geo.safeAreaInsets.top)
                    Spacer(minLength: 8)
                    centerContent
                    Spacer(minLength: 12)
                }
            }
        }
        .frame(height: 288)
        .ignoresSafeArea(.container, edges: .top)
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: headerStyle.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(flagEmoji)
                .font(.system(size: 220))
                .opacity(0.2)
                .blur(radius: 18)
                .offset(y: 10)
        }
    }

    private func topBar(safeTop: CGFloat) -> some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(localizationManager.localizedString("Back")))

            Spacer(minLength: 8)

            navCircleButton(icon: "chevron.left", enabled: canGoPrevious, action: onPrevious)
            favoriteButton
            difficultButton
            navCircleButton(icon: "chevron.right", enabled: canGoNext, action: onNext)
        }
        .padding(.horizontal, 16)
        // Ниже выреза/Dynamic Island и камеры — панель управления не перекрывается.
        .padding(.top, safeTop + 68)
    }

    private func navCircleButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(enabled ? 0.22 : 0.1))
                .clipShape(Circle())
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(Text(icon == "chevron.right"
            ? localizationManager.localizedString("learning.country.a11y.next")
            : localizationManager.localizedString("learning.country.a11y.previous")))
    }

    private var favoriteButton: some View {
        Button(action: onToggleFavorite) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isFavorite ? Color.yellow : .white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.22))
                .clipShape(Circle())
        }
        .buttonStyle(LearningIconButtonStyle())
        .accessibilityLabel(Text(localizationManager.localizedString("learning.country.a11y.favorite")))
    }

    private var difficultButton: some View {
        Button(action: onToggleDifficult) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isDifficult ? Color.orange : .white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.22))
                .clipShape(Circle())
        }
        .buttonStyle(LearningIconButtonStyle())
        .accessibilityLabel(Text(localizationManager.localizedString("learning.country.a11y.difficult")))
    }

    private var centerContent: some View {
        VStack(spacing: 10) {
            Text(flagEmoji)
                .font(.system(size: 56))
            Text(countryName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 16)
            if !regionName.isEmpty {
                Text(regionName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
            }
            CountryStatusBadgesView(
                isLearned: isLearned,
                isFavorite: isFavorite,
                isDifficult: isDifficult
            )
            .padding(.top, 4)
        }
    }
}

private struct LearningIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Status badges

struct CountryStatusBadgesView: View {
    let isLearned: Bool
    let isFavorite: Bool
    let isDifficult: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        let primary = isLearned
            ? localizationManager.localizedString("learning.status.learned")
            : localizationManager.localizedString("learning.status.not_learned")
        let secondary: String? = {
            if isDifficult { return localizationManager.localizedString("learning.status.difficult") }
            if isFavorite { return localizationManager.localizedString("learning.status.favorite_short") }
            return nil
        }()

        HStack(spacing: 8) {
            badge(primary, prominent: true)
            if let secondary {
                badge(secondary, prominent: false)
            }
        }
    }

    private func badge(_ text: String, prominent: Bool) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(prominent ? Color.white : Color.white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(prominent ? Color.blue.opacity(0.55) : Color.white.opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }
}

// MARK: - Stat card

struct CountryStatCardView: View {
    let systemIconName: String
    let emojiFallback: String?
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let emojiFallback {
                    Text(emojiFallback).font(.system(size: 20))
                } else {
                    Image(systemName: systemIconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(3)
                .minimumScaleFactor(0.88)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Info sections

struct CountryInfoSectionView: View {
    let title: String
    let rows: [(label: String, value: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    CountryInfoRowView(label: row.label, value: row.value)
                    if index < rows.count - 1 {
                        Divider().opacity(0.35)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

struct CountryInfoRowView: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(minWidth: 120, maxWidth: 140, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Train CTA

struct CountryTrainCTAButton: View {
    let title: String
    var subtitle: String? = nil
    /// Страна уже в очереди — кнопка неактивна, нейтральный стиль.
    var isInactive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .multilineTextAlignment(.leading)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isInactive ? Color.primary.opacity(0.55) : Color.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isInactive ? "checkmark.circle.fill" : "arrow.forward.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(isInactive ? Color.primary.opacity(0.45) : Color.white.opacity(0.95))
            }
            .foregroundColor(isInactive ? Color.primary.opacity(0.65) : .white)
            .padding(.vertical, 18)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isInactive
                            ? LinearGradient(
                                colors: [Color(UIColor.tertiarySystemFill), Color(UIColor.secondarySystemFill)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.48, blue: 0.96),
                                    Color(red: 0.12, green: 0.32, blue: 0.82)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isInactive ? Color.primary.opacity(0.08) : Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: isInactive ? .clear : Color.blue.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(LearningCTAButtonStyle())
        .disabled(isInactive)
        .accessibilityLabel(Text(title))
    }
}

// MARK: - Study selected flags (playlist)

struct LearningStudySelectedFlagsButton: View {
    let title: String
    /// Подзаголовок (например «3 / 6»), когда старт пока недоступен
    var subtitle: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "flag.checkered.2.crossed")
                    .font(.system(size: 22, weight: .semibold))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .multilineTextAlignment(.leading)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.88))
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.95))
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.62, blue: 0.38),
                                Color(red: 0.05, green: 0.48, blue: 0.42)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(LearningCTAButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .accessibilityLabel(Text(title))
    }
}

private struct LearningCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
