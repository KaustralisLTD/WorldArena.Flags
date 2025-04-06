import SwiftUI

struct AnswerButton: View {
    let country: Country
    let isSelected: Bool
    let isCorrect: Bool?
    let isIncorrect: Bool?
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            Text(LocalizationManager.shared.localizedCountryName(country))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .cornerRadius(10)
                .overlay(
                    HStack {
                        Spacer()
                        if isCorrect == true {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding(.trailing)
                        } else if isIncorrect == true {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .padding(.trailing)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonPressAnimation(isPressed: isPressed)
        .animation(.easeInOut(duration: 0.2), value: backgroundColor)
        .disabled(isCorrect != nil)
    }
    
    private var foregroundColor: Color {
        if isCorrect == nil {
            return .appTextPrimary
        } else if isSelected || isCorrect == true {
            return .white.opacity(0.9)
        } else {
            return .appTextPrimary.opacity(0.9)
        }
    }
    
    private var backgroundColor: Color {
        if isCorrect == nil {
            return Color.appBackgroundSecondary
        } else if isSelected {
            return isCorrect == true ? .green : .red
        } else if isCorrect == true {
            return .green
        } else {
            return Color.appBackgroundSecondary.opacity(0.9)
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
