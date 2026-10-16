import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Parental Gate для защиты детей от случайных покупок и переходов
/// Требует решения простой математической задачи взрослым
struct ParentalGate: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void
    
    @State private var firstNumber = Int.random(in: 1...9)
    @State private var secondNumber = Int.random(in: 1...9)
    @State private var userAnswer = ""
    @State private var showErrorMessage = false
    @State private var attempts = 0
    @FocusState private var isTextFieldFocused: Bool
    
    private var correctAnswer: Int {
        firstNumber + secondNumber
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Parental Verification")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This section is for adults only. Please solve the math problem below:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            // Math Problem
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Text("\(firstNumber)")
                        .font(.system(size: 32, weight: .bold))
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    Text("+")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("\(secondNumber)")
                        .font(.system(size: 32, weight: .bold))
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    Text("=")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    
                    TextField("?", text: $userAnswer)
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(width: 80, height: 60)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .focused($isTextFieldFocused)
                        .onChange(of: userAnswer) { newValue in
                            // Ограничиваем ввод только цифрами и максимум 2 символа
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered.count <= 2 {
                                userAnswer = filtered
                            } else {
                                userAnswer = String(filtered.prefix(2))
                            }
                        }
                }
                
                if showErrorMessage {
                    Text("Incorrect answer. Please try again.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Button("Continue") {
                    checkAnswer()
                }
                .font(.body)
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    userAnswer.isEmpty ? Color.gray : Color.blue
                )
                .cornerRadius(8)
                .disabled(userAnswer.isEmpty)
            }
            
            // Instructions
            Text("This verification ensures that only adults can access premium features and external links.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(radius: 10)
        .onAppear {
            // Автофокус на поле ввода
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func checkAnswer() {
        guard let answer = Int(userAnswer) else {
            showErrorFunc()
            return
        }
        
        if answer == correctAnswer {
            onSuccess()
        } else {
            showErrorFunc()
        }
    }
    
    private func showErrorFunc() {
        showErrorMessage = true
        attempts += 1
        
        // Генерируем новую задачу после 3 неправильных попыток
        if attempts >= 3 {
            generateNewProblem()
            attempts = 0
        }
        
        // Очищаем поле ввода
        userAnswer = ""
        
        // Скрываем ошибку через 3 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showErrorMessage = false
        }
    }
    
    private func generateNewProblem() {
        firstNumber = Int.random(in: 1...9)
        secondNumber = Int.random(in: 1...9)
    }
}

// MARK: - Parental Gate Overlay
struct ParentalGateOverlay: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                ParentalGate(
                    onSuccess: {
                        isPresented = false
                        onSuccess()
                    },
                    onCancel: {
                        isPresented = false
                    }
                )
                .padding(20)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
    }
}

#Preview {
    ParentalGate(
        onSuccess: { print("Success!") },
        onCancel: { print("Cancelled") }
    )
}
