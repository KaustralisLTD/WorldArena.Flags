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
    
    // Функция для создания изображения
    func generateImage(for size: CGFloat, scale: CGFloat = 1) -> UIImage {
        let scaledSize = CGSize(width: size * scale, height: size * scale)
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        
        return renderer.image { context in
            let hostingController = UIHostingController(rootView: AppIcon(size: size * scale))
            hostingController.view.frame = CGRect(origin: .zero, size: scaledSize)
            hostingController.view.backgroundColor = .clear
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
}

struct IconGenerator {
    static func generateAllIcons() {
        let icons: [(name: String, size: CGFloat, scale: CGFloat)] = [
            ("iPhone_60@2x", 60.0, 2.0),
            ("iPhone_60@3x", 60.0, 3.0),
            ("iPad_76@2x", 76.0, 2.0),
            ("iPadPro_83.5@2x", 83.5, 2.0),
            ("AppStore_1024", 1024.0, 1.0)
        ]
        
        // Получаем URL для директории документов
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let iconsDirectoryURL = documentsPath.appendingPathComponent("AppIcons")
        
        // Создаем директорию для иконок, если её нет
        try? FileManager.default.createDirectory(at: iconsDirectoryURL, withIntermediateDirectories: true)
        
        for (name, size, scale) in icons {
            let icon = AppIcon(size: size)
            let image = icon.generateImage(for: size, scale: scale)
            let imageData = image.pngData()
            let filePath = iconsDirectoryURL.appendingPathComponent("\(name).png")
            
            do {
                try imageData?.write(to: filePath)
                print("Иконка сохранена в: \(filePath.path)")
            } catch {
                print("Ошибка сохранения иконки \(name): \(error.localizedDescription)")
            }
        }
        
        // Выводим путь к директории с иконками
        print("\nВсе иконки сохранены в директории:\n\(iconsDirectoryURL.path)\n")
        
        #if DEBUG
        // Показываем путь к файлам в режиме отладки
        let activityVC = UIActivityViewController(
            activityItems: [iconsDirectoryURL],
            applicationActivities: nil
        )
        
        // Получаем текущее окно для показа share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
        #endif
    }
}

struct IconExporter: View {
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            AppIcon(size: 200)
            
            Button("Generate Icons") {
                IconGenerator.generateAllIcons()
                alertMessage = "Иконки сгенерированы. Проверьте консоль для путей к файлам."
                showingAlert = true
            }
            .padding()
        }
        .alert("Готово", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    IconExporter()
} 