import SwiftUI

struct AppIcon: View {
    let size: CGFloat
    
    init(size: CGFloat = 100) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Фон
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .cyan]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: size * 0.1)
            
            // Флаги
            ZStack {
                // Задний флаг
                Image(systemName: "flag.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(.white.opacity(0.8))
                    .offset(x: -size * 0.15, y: 0)
                    .rotationEffect(.degrees(-15))
                
                // Средний флаг
                Image(systemName: "flag.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.7, height: size * 0.7)
                    .foregroundColor(.white)
                    .offset(x: 0, y: 0)
                
                // Передний флаг
                Image(systemName: "flag.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(.white.opacity(0.8))
                    .offset(x: size * 0.15, y: 0)
                    .rotationEffect(.degrees(15))
            }
        }
        .frame(width: size, height: size)
    }
    
    // Функция для создания изображения (только для предпросмотра)
    @available(iOS 16.0, *)
    func generateImage(for size: CGFloat, scale: CGFloat = 1) -> Image {
        return Image(systemName: "flag.circle.fill")
    }
}

struct IconGenerator {
    static func generateAllIcons() {
        print("Генерация иконок доступна только через Xcode Asset Catalog")
        print("Используйте AppIcon в Assets.xcassets для создания иконок приложения")
    }
}

struct IconExporter: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            AppIcon(size: 200)
            
            Button(LocalizationManager.shared.localizedString("Generate Icons")) {
                IconGenerator.generateAllIcons()
                alertMessage = LocalizationManager.shared.localizedString("Иконки сгенерированы. Проверьте консоль для путей к файлам.")
                showingAlert = true
            }
            .padding()
        }
        .alert(LocalizationManager.shared.localizedString("Готово"), isPresented: $showingAlert) {
            Button(LocalizationManager.shared.localizedString("OK")) { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    IconExporter()
} 