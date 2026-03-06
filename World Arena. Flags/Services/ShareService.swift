import Foundation
#if os(iOS)
import UIKit
#endif

struct ShareService {
    static let shared = ShareService()
    
    private let appStoreId = "6744296834"
    
    var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreId)")
    }
    
    @MainActor func createShareMessage(score: Int) -> String {
        let message = String(format: LocalizationManager.shared.localizedString("Share Message"), score)
        if let url = appStoreURL {
            return "\(message)\n\n\(url.absoluteString)"
        }
        return message
    }
    
    @MainActor func shareGameResult(score: Int, totalQuestions: Int, timeElapsed: TimeInterval) {
        #if os(iOS)
        let accuracy = totalQuestions > 0 ? Int((Double(score) / Double(totalQuestions)) * 100) : 0
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        var message = "\(createShareMessage(score: score))\n\n\(LocalizationManager.shared.localizedString("Accuracy")): \(accuracy)%\n\(LocalizationManager.shared.localizedString("TIME")): \(timeText)"
        if let url = appStoreURL {
            message += "\n\n\(url.absoluteString)"
        }
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)

        if let topVC = topViewController() {
            if let pop = activityVC.popoverPresentationController {
                pop.sourceView = topVC.view
                pop.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
            topVC.present(activityVC, animated: true)
        } else {
            UIPasteboard.general.string = message
        }
        #else
        // Для macOS и других платформ можно использовать альтернативные методы шаринга
        print("Sharing not available on this platform")
        #endif
    }

    #if os(iOS)
    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root: UIViewController? = {
            if let base { return base }
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
            return scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? scene.windows.first?.rootViewController
        }()
        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }
    #endif
} 
