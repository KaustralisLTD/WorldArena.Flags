import SwiftUI

struct AppIcon: View {
    let size: CGFloat
    
    init(size: CGFloat = 100) {
        self.size = size
    }
    
    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
    
    // Функция для создания изображения (только для предпросмотра)
    @available(iOS 16.0, *)
    func generateImage(for size: CGFloat, scale: CGFloat = 1) -> Image {
        return Image("Logo")
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