import Foundation

extension Notification.Name {
    /// После слияния данных из iCloud в UserDefaults — перечитать профиль и прогресс карты.
    static let localProgressRestoredFromICloud = Notification.Name("localProgressRestoredFromICloud")
}

/// Резервная копия локального прогресса в **iCloud Key-Value** (тот же Apple ID + включённый iCloud).
/// После удаления приложения данные из контейнера приложения пропадают; KVS позволяет восстановить карту и профиль.
enum LocalProgressICloudMirror {
    private static let store = NSUbiquitousKeyValueStore.default

    static let keyCountryProgress = "learning.countryProgress.v1"
    static let keyMasteredContinents = "learning.masteredContinents.v1"
    static let keyWeeklyWeek = "learning.weeklyChallenge.weekStart"
    static let keyWeeklyCount = "learning.weeklyChallenge.weakSessionsCount"
    static let keyAvatarConfig = "user_avatar_configuration_v2"
    static let keyUserProfile = "user.profile.v1"

    /// До первого чтения `GameState` / `UserProfile`: подтянуть облако в UserDefaults (+ Keychain для профиля).
    static func restoreFromICloudIntoUserDefaultsIfMissing() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { Self.restoreFromICloudIntoUserDefaultsIfMissing() }
            return
        }
        store.synchronize()

        restoreDataKey(keyUserProfile, alsoKeychain: true)
        restoreDataKey(keyCountryProgress, alsoKeychain: false)
        restoreDataKey(keyAvatarConfig, alsoKeychain: false)
        restoreStringKey(keyMasteredContinents)

        if UserDefaults.standard.object(forKey: keyWeeklyWeek) == nil {
            if let n = store.object(forKey: keyWeeklyWeek) as? NSNumber {
                UserDefaults.standard.set(n.doubleValue, forKey: keyWeeklyWeek)
            }
        }
        if UserDefaults.standard.object(forKey: keyWeeklyCount) == nil {
            if let n = store.object(forKey: keyWeeklyCount) as? NSNumber {
                UserDefaults.standard.set(n.intValue, forKey: keyWeeklyCount)
            }
        }
        UserDefaults.standard.synchronize()
    }

    static func registerForRemoteUpdates() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in
            restoreFromICloudIntoUserDefaultsIfMissing()
            NotificationCenter.default.post(name: .localProgressRestoredFromICloud, object: nil)
        }
    }

    private static func restoreDataKey(_ key: String, alsoKeychain: Bool) {
        guard UserDefaults.standard.data(forKey: key) == nil else { return }
        guard let obj = store.object(forKey: key) else { return }
        let data: Data?
        if let d = obj as? Data {
            data = d
        } else if let d = obj as? NSData {
            data = d as Data
        } else {
            return
        }
        guard let data = data, !data.isEmpty else { return }
        UserDefaults.standard.set(data, forKey: key)
        if alsoKeychain {
            _ = KeychainStorage.save(data: data, forKey: key)
        }
    }

    private static func restoreStringKey(_ key: String) {
        let local = UserDefaults.standard.string(forKey: key) ?? ""
        guard local.isEmpty else { return }
        if let s = store.string(forKey: key), !s.isEmpty {
            UserDefaults.standard.set(s, forKey: key)
        }
    }

    static func pushData(_ data: Data?, forKey key: String) {
        guard let data = data, !data.isEmpty else { return }
        store.set(data, forKey: key)
        store.synchronize()
    }

    static func pushString(_ value: String, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    static func pushWeekly(weekStart: Double, sessionsCount: Int) {
        store.set(NSNumber(value: weekStart), forKey: keyWeeklyWeek)
        store.set(NSNumber(value: sessionsCount), forKey: keyWeeklyCount)
        store.synchronize()
    }
}
