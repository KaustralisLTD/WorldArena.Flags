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
        presentShare(message: message)
        #else
        print("Sharing not available on this platform")
        #endif
    }

    @MainActor func shareTimeChallengeResult(correct: Int, answered: Int, timeElapsed: TimeInterval) {
        #if os(iOS)
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        let L = LocalizationManager.shared
        let head = String(format: L.localizedString("Share TC headline"), correct, answered)
        var message = "\(head)\n\(L.localizedString("TIME")): \(timeText)"
        if let url = appStoreURL {
            message += "\n\n\(url.absoluteString)"
        }
        presentShare(message: message)
        #else
        print("Sharing not available on this platform")
        #endif
    }

    @MainActor func shareSurvivalResult(flagsSurvived: Int, correct: Int, maxStage: Int, timeElapsed: TimeInterval) {
        #if os(iOS)
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        let L = LocalizationManager.shared
        let head = String(format: L.localizedString("Share Survival headline"), flagsSurvived, correct, maxStage)
        var message = "\(head)\n\(L.localizedString("TIME")): \(timeText)"
        if let url = appStoreURL {
            message += "\n\n\(url.absoluteString)"
        }
        presentShare(message: message)
        #else
        print("Sharing not available on this platform")
        #endif
    }

    @MainActor
    func sharePostGameResult(score: Int, totalQuestions: Int, timeElapsed: TimeInterval, gameState: GameState) {
        #if os(iOS)
        shareRichPostGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed, gameState: gameState)
        #else
        if gameState.selectedPlayMode == .timeChallenge {
            let answered = max(1, gameState.lastGameResults.count)
            let correct = gameState.lastGameResults.filter(\.isCorrect).count
            shareTimeChallengeResult(correct: correct, answered: answered, timeElapsed: timeElapsed)
        } else if gameState.selectedPlayMode == .survival {
            let depth = gameState.survivalLastRunQuestions
            let correct = gameState.survivalLastRunCorrect
            let stage = gameState.survivalLastRunMaxStage
            shareSurvivalResult(flagsSurvived: depth, correct: correct, maxStage: stage, timeElapsed: timeElapsed)
        } else {
            shareGameResult(score: score, totalQuestions: totalQuestions, timeElapsed: timeElapsed)
        }
        #endif
    }

    #if os(iOS)
    @MainActor
    private func shareRichPostGameResult(score: Int, totalQuestions: Int, timeElapsed: TimeInterval, gameState: GameState) {
        var items: [Any] = []
        if let screenshot = captureScreenshot() {
            items.append(screenshot)
        }

        let L = LocalizationManager.shared
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        let appLink = appStoreURL?.absoluteString ?? "World Arena Flags"
        let promo = String(
            format: L.localizedString("Statistics Share Promo"),
            UserProfile.shared.bestScore,
            UserProfile.shared.accuracy,
            UserProfile.shared.totalGamesPlayed,
            appLink
        )

        let modeSummary: String = {
            if gameState.selectedPlayMode == .timeChallenge {
                let answered = max(1, gameState.lastGameResults.count)
                let correct = gameState.lastGameResults.filter(\.isCorrect).count
                return String(format: L.localizedString("Share TC headline"), correct, answered)
            }
            if gameState.selectedPlayMode == .survival {
                return String(
                    format: L.localizedString("Share Survival headline"),
                    gameState.survivalLastRunQuestions,
                    gameState.survivalLastRunCorrect,
                    gameState.survivalLastRunMaxStage
                )
            }
            return String(format: L.localizedString("Share Message"), score)
        }()

        let finalMessage = "\(modeSummary)\n\(L.localizedString("TIME")): \(timeText)\n\n\(promo)"
        items.append(finalMessage)

        if !presentShare(items: items) {
            presentShare(message: finalMessage)
        }
    }
    #endif

    #if os(iOS)
    private func presentShare(message: String) {
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
    }

    private func presentShare(items: [Any]) -> Bool {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let topVC = topViewController() {
            if let pop = activityVC.popoverPresentationController {
                pop.sourceView = topVC.view
                pop.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
            topVC.present(activityVC, animated: true)
            return true
        } else {
            return false
        }
    }

    private func captureScreenshot() -> UIImage? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
    #endif

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
