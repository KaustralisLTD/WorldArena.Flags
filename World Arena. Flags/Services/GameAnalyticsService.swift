import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// События для Firebase Analytics (режимы TC / Survival и weekly).
enum GameAnalyticsService {
    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        let sanitized = sanitizeParameters(parameters)
        Analytics.logEvent(name, parameters: sanitized)
        #else
        _ = name
        _ = parameters
        #endif
    }

    #if canImport(FirebaseAnalytics)
    private static func sanitizeParameters(_ parameters: [String: Any]?) -> [String: Any]? {
        guard let parameters, !parameters.isEmpty else { return nil }
        var out: [String: Any] = [:]
        for (key, value) in parameters {
            let k = String(key.prefix(40))
            switch value {
            case let n as Int:
                out[k] = n as NSNumber
            case let n as Int32:
                out[k] = n as NSNumber
            case let n as Int64:
                out[k] = n as NSNumber
            case let n as Double:
                out[k] = n as NSNumber
            case let n as Float:
                out[k] = n as NSNumber
            case let b as Bool:
                out[k] = b ? 1 : 0
            case let s as String:
                out[k] = String(s.prefix(100))
            default:
                out[k] = String(String(describing: value).prefix(100))
            }
        }
        return out
    }
    #endif
}
