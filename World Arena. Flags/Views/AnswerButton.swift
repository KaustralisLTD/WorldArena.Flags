import SwiftUI
#if os(iOS)
import UIKit
#endif

struct AnswerButton: View {
    let country: Country
    let isSelected: Bool
    let isCorrect: Bool?
    let isIncorrect: Bool?
    var compact: Bool = false
    /// Увеличенный компактный стиль (iPad landscape): больше padding и шрифт
    var compactLarge: Bool = false
    /// iPad портрет + крупный шрифт: два столбца, перенос в 2 строки, ограниченная высота
    var twoColumnLargeText: Bool = false
    /// iPad альбом: минимальная высота ячейки из расчёта свободного места (кнопки заполняют экран)
    var iPadLandscapeMinCellHeight: CGFloat? = nil
    var tabletStyle = false
    let action: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.sizeCategory) private var sizeCategory
    
    #if os(iOS)
    private static var isLargeAccessibilityText: Bool {
        UIFont.preferredFont(forTextStyle: .body).pointSize > 20
    }
    #else
    private static var isLargeAccessibilityText: Bool { false }
    #endif

    private var useCompactStyle: Bool { compact }
    private var largeTextPhoneMode: Bool {
        horizontalSizeClass != .regular
            && (sizeCategory.isAccessibilityCategory || sizeCategory >= .extraExtraLarge || Self.isLargeAccessibilityText)
    }
    private var answerFont: Font {
        if tabletStyle { return .title3.weight(.semibold) }
        if let cellH = iPadLandscapeMinCellHeight, compact {
            let s = min(28, max(17, cellH * 0.24))
            return .system(size: s, weight: .semibold, design: .rounded)
        }
        if twoColumnLargeText {
            // Альбом iPad + крупный шрифт: ниже, чем портрет, чтобы влезало в maxHeight сетки
            if useCompactStyle {
                #if os(iOS)
                let body = UIFont.preferredFont(forTextStyle: .body).pointSize
                return .system(size: min(30, max(22, body * 1.05)), weight: .semibold, design: .rounded)
                #else
                return .system(size: 26, weight: .semibold, design: .rounded)
                #endif
            }
            return .system(size: 40, weight: .medium)
        }
        if useCompactStyle { return compactLarge ? .title3 : .subheadline }
        if largeTextPhoneMode {
            return .body.weight(.semibold)
        }
        #if os(iOS)
        if Self.isLargeAccessibilityText {
            let bodySize = UIFont.preferredFont(forTextStyle: .body).pointSize
            if horizontalSizeClass == .regular {
                return .system(size: min(26, bodySize + 4), weight: .semibold, design: .rounded)
            }
            return .system(size: min(22, bodySize + 2), weight: .medium)
        }
        #endif
        return horizontalSizeClass == .regular ? .title2 : .body.weight(.medium)
    }
    private var answerPadding: CGFloat {
        if tabletStyle { return 20 }
        if let cellH = iPadLandscapeMinCellHeight, compact {
            return min(18, max(8, cellH * 0.12))
        }
        if twoColumnLargeText { return useCompactStyle ? 12 : 16 }
        if useCompactStyle { return compactLarge ? 10 : 6 }
        if largeTextPhoneMode { return 12 }
        #if os(iOS)
        if horizontalSizeClass == .regular && Self.isLargeAccessibilityText { return 22 }
        #endif
        return horizontalSizeClass == .regular ? 20 : 12
    }
    private var compactIconSize: CGFloat { compactLarge ? 20 : 14 }
    private var compactCornerRadius: CGFloat {
        if iPadLandscapeMinCellHeight != nil { return 12 }
        return compactLarge ? 10 : 8
    }

    private var twoColumnCellMaxHeight: CGFloat? {
        guard twoColumnLargeText else { return nil }
        if let h = iPadLandscapeMinCellHeight, compact { return h }
        return useCompactStyle ? 92 : 110
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(LocalizationManager.shared.localizedCountryName(country))
                    .font(answerFont)
                    .lineLimit(tabletStyle ? nil : (horizontalSizeClass == .regular ? 2 : nil))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isCorrect == true ? "checkmark.circle.fill" : (isIncorrect == true ? "xmark.circle.fill" : "circle"))
                    .font(.system(size: useCompactStyle ? 18 : 21, weight: .medium))
                    .foregroundColor(isCorrect == true ? .green : (isIncorrect == true ? .red : Color.primary.opacity(0.14)))
                    .accessibilityHidden(true)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, answerPadding)
            .frame(minHeight: tabletStyle ? 72 : max(48, iPadLandscapeMinCellHeight ?? 0))
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(backgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(borderColor, lineWidth: isCorrect == true || isIncorrect == true ? 1.5 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(QuizAnswerPressStyle(reduceMotion: reduceMotion))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: backgroundColor)
        .disabled(isCorrect != nil)
        .accessibilityIdentifier("quiz.answer." + country.id)
        .accessibilityValue(isCorrect == true ? LocalizationManager.shared.localizedString("Correct") : (isIncorrect == true ? LocalizationManager.shared.localizedString("Wrong") : ""))
    }

    private var foregroundColor: Color { .primary }

    private var backgroundColor: Color {
        if isCorrect == true { return Color.green.opacity(0.12) }
        if isIncorrect == true { return Color.red.opacity(0.10) }
        return Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var borderColor: Color {
        if isCorrect == true { return .green.opacity(0.65) }
        if isIncorrect == true { return .red.opacity(0.65) }
        return Color.primary.opacity(0.07)
    }
}

private struct QuizAnswerPressStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.80 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// Добавляем модификатор для анимации нажатия
extension View {
    func pressAnimation(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
} 
