import Foundation
#if os(iOS)
import UIKit
#endif

@MainActor
enum CapitalAppIconService {
    static func updateForCurrentLanguage() {
        #if os(iOS)
        guard !CommandLine.arguments.contains("UITesting"), !UserDefaults.standard.bool(forKey: "capitals.appIcon.manualChoice"), UIApplication.shared.applicationState == .active, UIApplication.shared.supportsAlternateIcons else { return }
        let locale = LocalizationManager.shared.currentBundleLanguageCode
        let name: String? = locale == "en" ? nil : "CapitalIcon_" + locale.replacingOccurrences(of: "-", with: "_")
        guard UIApplication.shared.alternateIconName != name else { return }
        UIApplication.shared.setAlternateIconName(name) { error in
            if let error { print("Capital app icon update: \(error.localizedDescription)") }
        }
        #endif
    }
}
