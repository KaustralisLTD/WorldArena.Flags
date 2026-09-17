import SwiftUI
#if os(iOS)
import UIKit
#endif
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Сервис награждаемой рекламы (видео за жизни). Production AdMob — реальные показы и начисления.
/// Реальная реклама: реальное устройство + сборка Release/TestFlight/App Store. На симуляторе AdMob может показывать тестовые объявления.
@MainActor
final class RewardedAdService: NSObject, ObservableObject {
    static let shared = RewardedAdService()
    /// Включить кнопку «Видео за +3 жизни» в алерте «Жизни закончились».
    static let isRewardedAdEnabled = true
    /// Награда за просмотр рекламы: +3 жизни.
    static let livesRewardAmount = 3

    @Published private(set) var isReady = false
    @Published private(set) var isLoading = false

    /// Rewarded: SDK может вызвать `userDidEarnRewardHandler` до закрытия full-screen.
    /// Чтобы UX был одинаковым (особенно при старте игры с Главной), выполняем награду
    /// после `adDidDismissFullScreenContent`, если она была заработана.
    private var pendingRewardAction: (() -> Void)?
    private var didEarnRewardForCurrentAd: Bool = false

    #if canImport(GoogleMobileAds)
    private var rewardedAd: RewardedAd?
    private let adUnitID: String
    #endif

    override init() {
        #if canImport(GoogleMobileAds)
        #if DEBUG
        // Официальный тестовый rewarded из документации Google — проверка, что SDK грузит/показывает рекламу.
        self.adUnitID = "ca-app-pub-3940256099942544/1712485313"
        #else
        // Production Rewarded «Reward 3 Lifes New 2» (+3 жизни), AdMob.
        self.adUnitID = "ca-app-pub-7269040792290642/4104159559"
        #endif
        #endif
        super.init()
    }

    /// Подробный разбор ошибки AdMob: публичное сообщение часто только «No ad to show»; детали — в domain/code/userInfo.
    private nonisolated static func logLoadFailure(error: Error, unitId: String) {
        print("Rewarded ad failed to load — adUnitId: \(unitId)")
        var current: Error? = error
        var depth = 0
        while let err = current, depth < 6 {
            let ns = err as NSError
            print("  [\(depth)] \(ns.domain) code=\(ns.code) — \(ns.localizedDescription)")
            if !ns.userInfo.isEmpty {
                print("      userInfo: \(ns.userInfo)")
            }
            current = ns.userInfo[NSUnderlyingErrorKey] as? Error
            depth += 1
        }
    }

    #if canImport(GoogleMobileAds)
    /// Google demo rewarded — на симуляторе **всегда** (даже Release), иначе часто production → «No ad to show».
    private static let googleDemoRewardedUnitId = "ca-app-pub-3940256099942544/1712485313"

    private static func resolvedRewardedAdUnitId(fallback: String) -> String {
        #if targetEnvironment(simulator)
        return googleDemoRewardedUnitId
        #elseif DEBUG
        return fallback
        #else
        return UserDefaults.standard.string(forKey: "admob.rewarded.lives.unitId") ?? fallback
        #endif
    }
    #endif

    /// Установить свой Ad Unit ID (вызовите из Release; в Debug сохранение в UserDefaults отключено).
    func configure(adUnitID: String) {
        #if canImport(GoogleMobileAds)
        #if !DEBUG
        UserDefaults.standard.set(adUnitID, forKey: "admob.rewarded.lives.unitId")
        #endif
        #endif
        Task { await loadAd() }
    }

    /// Загрузить рекламу (вызывается при старте и после показа).
    func loadAd() async {
        #if canImport(GoogleMobileAds)
        let unitId = Self.resolvedRewardedAdUnitId(fallback: adUnitID)
        #if targetEnvironment(simulator)
        print("RewardedAdService: симулятор → demo rewarded unit: \(unitId)")
        #elseif DEBUG
        print("RewardedAdService: Debug → adUnitId: \(unitId)")
        #endif
        isLoading = true
        isReady = false
        do {
            rewardedAd = try await RewardedAd.load(with: unitId, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
            isReady = true
        } catch {
            Self.logLoadFailure(error: error, unitId: unitId)
        }
        isLoading = false
        #else
        isReady = false
        isLoading = false
        #endif
    }

    /// Показать рекламу.
    /// Документация: `userDidEarnRewardHandler` вызывается при заработке награды; для объявлений Google он
    /// обычно срабатывает до `adDidDismissFullScreenContent` (у медиации порядок может отличаться).
    /// После загрузки можно читать `adReward` (тип/кол-во от сети); в приложении жизни начисляем фиксированно (`livesRewardAmount`).
    /// Награду в UI выдаём после закрытия fullscreen (`adDidDismiss…`), когда SDK уже выставил флаг в обработчике.
    /// Если реклама недоступна — вызывается onUnavailable (если задан).
    func showIfAvailable(from viewController: UIViewController?, onReward: @escaping () -> Void, onUnavailable: (() -> Void)? = nil) {
        #if canImport(GoogleMobileAds)
        // Сбрасываем состояние на каждый показ.
        pendingRewardAction = nil
        didEarnRewardForCurrentAd = false

        guard let ad = rewardedAd else {
            print("RewardedAdService: no rewarded ad loaded, cannot present.")
            // Пробуем подгрузить объявление на будущее.
            Task { await loadAd() }
            onUnavailable?()
            return
        }
        guard let root = viewController ?? Self.rootViewController() else {
            print("RewardedAdService: rootViewController is nil, cannot present rewarded ad.")
            // На всякий случай инициируем перезагрузку, чтобы не зависнуть без объявлений.
            Task { await loadAd() }
            onUnavailable?()
            return
        }
        rewardedAd = nil
        isReady = false
        pendingRewardAction = onReward
        #if DEBUG
        print("RewardedAd: adReward=\(ad.adReward) · в игре начисляем \(Self.livesRewardAmount) жизней")
        #endif
        // В доках иногда `present(from: nil, …)` — на iOS нужен реальный VC; иначе показ может не открыться.
        ad.present(from: root, userDidEarnRewardHandler: {
            Task { @MainActor in
                self.didEarnRewardForCurrentAd = true
            }
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
extension RewardedAdService: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            if didEarnRewardForCurrentAd, let action = pendingRewardAction {
                // Выполняем награду только после закрытия рекламы.
                action()
            }
            pendingRewardAction = nil
            didEarnRewardForCurrentAd = false
            rewardedAd = nil
            isReady = false
            await loadAd()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        RewardedAdService.logLoadFailure(error: error, unitId: "(present)")
        Task { @MainActor in
            rewardedAd = nil
            isReady = false
            await loadAd()
        }
    }
}
#endif
