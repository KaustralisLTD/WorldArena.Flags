import Foundation

#if os(iOS) && canImport(GameKit)
import UIKit
import GameKit
#endif

/// Game Center Achievements:
/// - аутентифицирует игрока через `GKLocalPlayer`
/// - репортит прогресс достижений через `GKAchievement.report`
/// - (опционально) открывает UI достижений через `GKGameCenterViewController`
final class GameCenterAchievementsService {
    static let shared = GameCenterAchievementsService()

#if os(iOS) && canImport(GameKit)
    /// Делегат обязателен до `present` для `GKGameCenterViewController`, иначе UI не открывается.
    private final class GameCenterPresentationDelegate: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }

    private let gameCenterPresentationDelegate = GameCenterPresentationDelegate()

    private(set) var isAuthenticated: Bool = false
    private var lastNonRepeatableReportDate: Date?
    private let reportCooldownSeconds: TimeInterval = 8

    // Повторяемая ачивка по звёздам:
    // xp_10000 = +1 звезда за каждые дополнительные +10.000 XP.
    private let repeatableXpAchievementId = "xp_10000"
    private let repeatableXpStep: Int = 10_000
#else
    private(set) var isAuthenticated: Bool = false
#endif

    private init() {}

#if os(iOS) && canImport(GameKit)
    private func rootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let foregroundScenes = scenes.filter {
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }
        let candidates = foregroundScenes.isEmpty ? scenes : foregroundScenes
        guard let windowScene = candidates.first else { return nil }
        let window = windowScene.windows.first(where: \.isKeyWindow)
            ?? windowScene.windows.first
        guard let window else { return nil }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController {
            vc = presented
        }
        return vc
    }

    func authenticateIfNeeded(completion: ((Bool) -> Void)? = nil) {
        let localPlayer = GKLocalPlayer.local
        if localPlayer.isAuthenticated {
            isAuthenticated = true
            DispatchQueue.main.async {
                completion?(true)
            }
            return
        }

        localPlayer.authenticateHandler = { [weak self] authVC, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if let authVC, let presenter = self.rootViewController() {
                    presenter.present(authVC, animated: true)
                }
                self.isAuthenticated = localPlayer.isAuthenticated
                completion?(self.isAuthenticated)
            }
        }
    }

    @MainActor
    func reportAllAchievementsProgress(userProfile: UserProfile) {
        guard isAuthenticated else { return }

        let now = Date()
        let allowNonRepeatableReports: Bool = {
            guard let last = lastNonRepeatableReportDate else { return true }
            return now.timeIntervalSince(last) >= reportCooldownSeconds
        }()
        if allowNonRepeatableReports {
            lastNonRepeatableReportDate = now
        }

        // Собираем достижения, у которых прогресс реально обновился с прошлого репорта.
        var toReport: [GKAchievement] = []

        for def in userProfile.allAchievementDefinitions {
            let (current, target) = userProfile.progress(for: def)
            guard target > 0 else { continue }

            // Repeatable: xp_10000
            if def.id == repeatableXpAchievementId, allowNonRepeatableReports || current >= repeatableXpStep {
                let completedCount = current / repeatableXpStep
                let lastCompletedCountKey = "gc.achiev.repeat.lastCount.\(def.id)"
                let lastCompletedCount = UserDefaults.standard.integer(forKey: lastCompletedCountKey)

                if completedCount > lastCompletedCount {
                    // Репортим каждое новое "закрытие" (за каждую новую звезду).
                    for _ in lastCompletedCount..<completedCount {
                        let achievement = GKAchievement(identifier: def.id)
                        achievement.percentComplete = 100.0
                        achievement.showsCompletionBanner = true
                        GKAchievement.report([achievement], withCompletionHandler: { error in
                            if let error {
                                print("GameCenter: Failed repeatable report \(def.id): \(error.localizedDescription)")
                            }
                        })
                    }
                    UserDefaults.standard.set(completedCount, forKey: lastCompletedCountKey)
                }

                // Также обновляем прогресс до следующей звезды (не показывая баннер).
                let remainder = current % repeatableXpStep
                let remainderPercent = max(0.0, min(100.0, (Double(remainder) / Double(repeatableXpStep)) * 100.0))
                let lastRemainderPercentKey = "gc.achiev.repeat.lastRemainderPercent.\(def.id)"
                let lastRemainderPercent = UserDefaults.standard.double(forKey: lastRemainderPercentKey)
                if remainderPercent > lastRemainderPercent + 0.5 {
                    let a = GKAchievement(identifier: def.id)
                    a.percentComplete = remainderPercent
                    a.showsCompletionBanner = false
                    GKAchievement.report([a], withCompletionHandler: { error in
                        if let error {
                            print("GameCenter: Failed repeatable remainder report \(def.id): \(error.localizedDescription)")
                        }
                    })
                    UserDefaults.standard.set(remainderPercent, forKey: lastRemainderPercentKey)
                }

                // Не добавляем в общий toReport — handled отдельно.
                continue
            }

            // Если сейчас нельзя репортить non-repeatable (троттлинг), пропускаем.
            guard allowNonRepeatableReports else { continue }

            let ratio = Double(max(0, min(current, target))) / Double(target)
            let percent = max(0.0, min(100.0, ratio * 100.0))

            let key = "gc.achiev.lastPercent.\(def.id)"
            let lastPercent = UserDefaults.standard.double(forKey: key)

            // Репортим только если прогресс заметно вырос (минимальный порог от шума).
            if percent <= lastPercent + 0.5 { continue }

            let achievement = GKAchievement(identifier: def.id)
            achievement.percentComplete = percent
            achievement.showsCompletionBanner = percent >= 100.0
            toReport.append(achievement)
        }

        guard !toReport.isEmpty else { return }

        GKAchievement.report(toReport, withCompletionHandler: { error in
            if let error = error {
                print("GameCenter: Failed to report achievements: \(error.localizedDescription)")
                return
            }
            for a in toReport {
                let key = "gc.achiev.lastPercent.\(a.identifier)"
                UserDefaults.standard.set(a.percentComplete, forKey: key)
            }
            print("GameCenter: Achievements progress reported: \(toReport.map { $0.identifier })")
        })
    }

    @MainActor
    func showAchievementsUI() {
        guard isAuthenticated else { return }
        guard let presenter = rootViewController() else { return }
        let vc = GKGameCenterViewController(state: .achievements)
        vc.gameCenterDelegate = gameCenterPresentationDelegate
        presenter.present(vc, animated: true)
    }

    func authenticateAndShowAchievementsUI() {
        authenticateIfNeeded { [weak self] ok in
            guard ok else { return }
            Task { @MainActor in
                guard let self else { return }
                self.reportAllAchievementsProgress(userProfile: UserProfile.shared)
                self.showAchievementsUI()
            }
        }
    }
#else
    func authenticateIfNeeded(completion: ((Bool) -> Void)? = nil) {}
    func reportAllAchievementsProgress(userProfile: UserProfile) {}
    func showAchievementsUI() {}
    func authenticateAndShowAchievementsUI() {}
#endif
}

