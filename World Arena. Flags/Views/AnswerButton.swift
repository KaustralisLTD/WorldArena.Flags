import SwiftUI

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
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var useCompactStyle: Bool { compact }
    private var answerFont: Font {
        if twoColumnLargeText { return .system(size: 40, weight: .medium) }
        if useCompactStyle { return compactLarge ? .title3 : .subheadline }
        return horizontalSizeClass == .regular ? .title2 : .body
    }
    private var answerPadding: CGFloat {
        if twoColumnLargeText { return 16 }
        if useCompactStyle { return compactLarge ? 10 : 6 }
        return horizontalSizeClass == .regular ? 20 : 16
    }
    private var compactIconSize: CGFloat { compactLarge ? 20 : 14 }
    private var compactCornerRadius: CGFloat { compactLarge ? 10 : 8 }
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            Text(LocalizationManager.shared.localizedCountryName(country))
                .font(answerFont)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(twoColumnLargeText ? 0.85 : (useCompactStyle ? 0.7 : 0.8))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: horizontalSizeClass == .regular && !useCompactStyle ? 400 : .infinity)
                .frame(maxHeight: twoColumnLargeText ? 110 : nil)
                .padding(answerPadding)
                .background(
                    RoundedRectangle(cornerRadius: useCompactStyle ? compactCornerRadius : 12)
                        .fill(backgroundColor)
                )
                .overlay(
                    HStack {
                        Spacer()
                        if isCorrect == true {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: twoColumnLargeText ? 36 : (useCompactStyle ? compactIconSize : 20)))
                                .foregroundColor(.green)
                                .padding(.trailing, twoColumnLargeText ? 16 : (useCompactStyle ? (compactLarge ? 10 : 6) : 12))
                        } else if isIncorrect == true {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: twoColumnLargeText ? 36 : (useCompactStyle ? compactIconSize : 20)))
                                .foregroundColor(.red)
                                .padding(.trailing, twoColumnLargeText ? 16 : (useCompactStyle ? (compactLarge ? 10 : 6) : 12))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: useCompactStyle ? (compactLarge ? 10 : 6) : 10)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonPressAnimation(isPressed: isPressed)
        .animation(.easeInOut(duration: 0.2), value: backgroundColor)
        .disabled(isCorrect != nil)
    }
    
    private var foregroundColor: Color {
        if isCorrect == nil {
            return .primary
        } else if isSelected || isCorrect == true {
            return .white.opacity(0.9)
        } else {
            return .primary.opacity(0.9)
        }
    }
    
    private var backgroundColor: Color {
        if isCorrect == nil {
            return Color(uiColor: .secondarySystemBackground)
        } else if isSelected {
            return isCorrect == true ? .green : .red
        } else if isCorrect == true {
            return .green
        } else {
            return Color(uiColor: .secondarySystemBackground)
        }
    }
    
    private var borderColor: Color {
        if isCorrect == true {
            return .green.opacity(0.3)
        } else if isIncorrect == true {
            return .red.opacity(0.3)
        } else if isSelected {
            return .blue.opacity(0.3)
        } else {
            return .textSecondary.opacity(0.3)
        }
    }
}

// Добавляем модификатор для анимации нажатия
extension View {
    func pressAnimation(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
} 
