import Foundation

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
} 
