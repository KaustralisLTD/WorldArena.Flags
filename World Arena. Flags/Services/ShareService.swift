import Foundation
#if os(iOS)
import UIKit
#endif

struct ShareService {
    static let shared = ShareService()
    
    private let appStoreId = "YOUR_APP_STORE_ID" // Заменить на реальный ID после публикации
    
    var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/idYOUR_APP_STORE_ID")
    }
    
    @MainActor func createShareMessage(score: Int) -> String {
        let message = String(format: LocalizationManager.shared.localizedString("Share Message"), score)
        if let url = appStoreURL {
            return "\(message)\n\n\(url.absoluteString)"
        }
        return message
    }
    
    @MainActor func shareGameResult(score: Int, totalQuestions: Int, timeElapsed: TimeInterval) {
        // Добавить родительский контроль
        guard parentalGatePassed() else {
            print("❌ Parental gate not passed")
            return
        }

        #if os(iOS)
        let message = createShareMessage(score: score)
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
        #else
        // Для macOS и других платформ можно использовать альтернативные методы шаринга
        print("Sharing not available on this platform")
        #endif
    }

    private func parentalGatePassed() -> Bool {
        // Логика проверки родительского контроля
        // Например, простая математическая задача
        return true // Заменить на реальную проверку
    }
} 
