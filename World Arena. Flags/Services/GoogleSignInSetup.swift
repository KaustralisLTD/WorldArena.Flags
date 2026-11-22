import Foundation

/// Validate before calling GoogleSignIn: missing settings raise Objective-C
/// exceptions in the SDK, which Swift do/catch cannot handle.
enum GoogleSignInSetup {
    static func clientID(info: [String: Any]) -> String? {
        guard let clientID = info["GIDClientID"] as? String,
              clientID.hasSuffix(".apps.googleusercontent.com"),
              !clientID.contains(where: { $0.isWhitespace }),
              clientID.count > ".apps.googleusercontent.com".count else { return nil }
        let reversed = clientID.split(separator: ".").reversed().joined(separator: ".")
        let schemes = (info["CFBundleURLTypes"] as? [[String: Any]] ?? [])
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        return schemes.contains(reversed) ? clientID : nil
    }

    static var configuredClientID: String? {
        clientID(info: Bundle.main.infoDictionary ?? [:])
    }
}
