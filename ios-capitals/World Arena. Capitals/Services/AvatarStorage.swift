import Foundation

final class AvatarStorage {
    static let shared = AvatarStorage()
    private let key = "user_avatar_configuration_v2"

    private init() {}

    func save(_ configuration: AvatarConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        UserDefaults.standard.set(data, forKey: key)
        LocalProgressICloudMirror.pushData(data, forKey: LocalProgressICloudMirror.keyAvatarConfig)
    }

    func load() -> AvatarConfiguration? {
        if UserDefaults.standard.data(forKey: key) == nil,
           let obj = NSUbiquitousKeyValueStore.default.object(forKey: LocalProgressICloudMirror.keyAvatarConfig) {
            let data: Data?
            if let d = obj as? Data { data = d } else if let d = obj as? NSData { data = d as Data } else { data = nil }
            if let data = data, !data.isEmpty {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AvatarConfiguration.self, from: data)
    }
}

