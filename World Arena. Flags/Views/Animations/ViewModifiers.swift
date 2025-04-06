import SwiftUI

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct ScaleButtonPress: ViewModifier {
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.2), value: scale)
    }
}

struct PressAnimationModifier: ViewModifier {
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

extension View {
    func shake(with amount: CGFloat) -> some View {
        modifier(ShakeEffect(amount: amount, animatableData: amount))
    }
    
    func buttonPressAnimation(isPressed: Bool) -> some View {
        modifier(PressAnimationModifier(isPressed: isPressed))
    }
} 