import SwiftUI
#if os(iOS)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Сервис награждаемой рекламы (видео за жизни).
/// Без подключённого Google Mobile Ads SDK работает заглушка (кнопка будет, но награда не выдаётся до настройки).
@MainActor
final class RewardedAdService: NSObject, ObservableObject {
    static let shared = RewardedAdService()
    /// Включить кнопку «Видео за +3 жизни» в алерте «Жизни закончились».
    static let isRewardedAdEnabled = true
    /// Награда за просмотр рекламы: +3 жизни.
    static let livesRewardAmount = 3

    @Published private(set) var isReady = false
    @Published private(set) var isLoading = false

    #if canImport(GoogleMobileAds)
    private var rewardedAd: GADRewardedAd?
    private let adUnitID: String
    #endif

    override init() {
        #if canImport(GoogleMobileAds)
        // Ad Unit ID из AdMob: вознаграждаемая реклама «3 lifes».
        self.adUnitID = "ca-app-pub-7269040792290642/8749486730"
        #endif
        super.init()
    }

    /// Установить свой Ad Unit ID (вызвать при старте приложения после получения ID из AdMob).
    func configure(adUnitID: String) {
        #if canImport(GoogleMobileAds)
        // Сохранить в UserDefaults и использовать вместо тестового — можно добавить при необходимости.
        UserDefaults.standard.set(adUnitID, forKey: "admob.rewarded.lives.unitId")
        #endif
        Task { await loadAd() }
    }

    /// Загрузить рекламу (вызывается при старте и после показа).
    func loadAd() async {
        #if canImport(GoogleMobileAds)
        let unitId = UserDefaults.standard.string(forKey: "admob.rewarded.lives.unitId") ?? adUnitID
        isLoading = true
        isReady = false
        do {
            rewardedAd = try await GADRewardedAd.load(withAdUnitID: unitId, request: GADRequest())
            rewardedAd?.fullScreenContentDelegate = self
            isReady = true
        } catch {
            print("Rewarded ad failed to load: \(error.localizedDescription)")
        }
        isLoading = false
        #else
        isReady = false
        isLoading = false
        #endif
    }

    /// Показать рекламу. По завершении просмотра вызывается onReward на главном потоке.
    func showIfAvailable(from viewController: UIViewController?, onReward: @escaping () -> Void) {
        #if canImport(GoogleMobileAds)
        guard let ad = rewardedAd else {
            onReward()
            return
        }
        guard let root = viewController ?? Self.rootViewController() else {
            onReward()
            return
        }
        rewardedAd = nil
        isReady = false
        ad.present(fromRootViewController: root, userDidEarnRewardHandler: {
            onReward()
        })
        Task { await loadAd() }
        #else
        // Без Google Mobile Ads SDK награда не выдаётся — добавьте пакет и настройте AdMob (см. Docs/RewardedAd_Setup.md).
        #endif
    }

    #if canImport(GoogleMobileAds)
    private static func rootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController {
            vc = presented
        }
        return vc
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension RewardedAdService: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            rewardedAd = nil
            isReady = false
            await loadAd()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Rewarded ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            rewardedAd = nil
            isReady = false
            await loadAd()
        }
    }
}
#endif
