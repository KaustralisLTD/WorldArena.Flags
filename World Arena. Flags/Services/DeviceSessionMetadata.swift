import Foundation
#if os(iOS)
import UIKit
#endif

/// Данные устройства и клиента для записи в auth_sessions на сервере и отображения в «Выполнен вход».
enum DeviceSessionMetadata {
#if os(iOS)
    static var marketingDeviceName: String {
        var uts = utsname()
        uname(&uts)
        let machine = withUnsafePointer(to: &uts.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? ""
            }
        }
        let id = machine.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
        if let name = knownIOSDevices[id] { return name }
        if id == "i386" || id == "x86_64" || id == "arm64" { return "Simulator" }
        if id.isEmpty { return UIDevice.current.model }
        return id
    }

    static var appVersionLine: String {
        let bundle = Bundle.main
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "World Arena Flags"
        let displayName = (name?.isEmpty == false) ? name! : fallbackName
        let ver = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
        return "\(displayName) iOS \(ver)"
    }

    /// Код страны по региону ОС (без GPS/IP). Используем только как мягкий hint.
    static var approximateLocationCountryCode: String? {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            if let regionCode = Locale.autoupdatingCurrent.region?.identifier.trimmingCharacters(in: .whitespacesAndNewlines),
               !regionCode.isEmpty {
                return regionCode.uppercased()
            }
        }
        #endif
        if let regionCode = Locale.autoupdatingCurrent.regionCode?.trimmingCharacters(in: .whitespacesAndNewlines),
           !regionCode.isEmpty {
            return regionCode.uppercased()
        }
        return nil
    }

    /// Вкладывается в JSON при auth/register, auth/login, auth/social-login.
    static var clientInfoForAuth: [String: String] {
        var d: [String: String] = [
            "deviceModel": marketingDeviceName,
            "appVersion": appVersionLine
        ]
        if let countryCode = approximateLocationCountryCode {
            d["locationCountryCode"] = countryCode
        }
        return d
    }

    // Часть идентификаторов hw.machine (актуальные и распространённые модели).
    private static let knownIOSDevices: [String: String] = [
        "iPhone8,1": "iPhone 6s", "iPhone8,2": "iPhone 6s Plus", "iPhone8,4": "iPhone SE (1st gen)",
        "iPhone9,1": "iPhone 7", "iPhone9,2": "iPhone 7 Plus", "iPhone9,3": "iPhone 7", "iPhone9,4": "iPhone 7 Plus",
        "iPhone10,1": "iPhone 8", "iPhone10,2": "iPhone 8 Plus", "iPhone10,3": "iPhone X", "iPhone10,4": "iPhone 8",
        "iPhone10,5": "iPhone 8 Plus", "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS", "iPhone11,4": "iPhone XS Max", "iPhone11,6": "iPhone XS Max", "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11", "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max", "iPhone12,8": "iPhone SE (2nd gen)",
        "iPhone13,1": "iPhone 12 mini", "iPhone13,2": "iPhone 12", "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max", "iPhone14,4": "iPhone 13 mini", "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE (3rd gen)", "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max", "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max", "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
        "iPhone18,1": "iPhone 17 Pro", "iPhone18,2": "iPhone 17 Pro Max", "iPhone18,3": "iPhone 17", "iPhone18,4": "iPhone 17 Plus",
        "iPad13,18": "iPad (10th gen)", "iPad13,19": "iPad (10th gen)", "iPad14,1": "iPad mini (6th gen)", "iPad14,2": "iPad mini (6th gen)",
        "iPad13,16": "iPad Air (5th gen)", "iPad13,17": "iPad Air (5th gen)", "iPad14,3": "iPad Pro 11-inch (4th gen)", "iPad14,4": "iPad Pro 11-inch (4th gen)",
        "iPad14,5": "iPad Pro 12.9-inch (6th gen)", "iPad14,6": "iPad Pro 12.9-inch (6th gen)",
    ]
#else
    static var marketingDeviceName: String { "Mac" }
    static var appVersionLine: String {
        let ver = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
        return "World Arena Flags \(ver)"
    }
    static var approximateLocationCountryCode: String? { nil }
    static var clientInfoForAuth: [String: String] {
        ["deviceModel": marketingDeviceName, "appVersion": appVersionLine]
    }
#endif

    /// Локация сессии для UI: показываем только корректно распознанную страну и локализуем в язык приложения.
    static func localizedSessionLocationLabel(_ raw: String?, countryCode: String?, appLocale: Locale) -> String? {
        if let cc = countryCode?.trimmingCharacters(in: .whitespacesAndNewlines), cc.count == 2 {
            let upper = cc.uppercased()
            if Locale.isoRegionCodes.contains(upper) {
                return localizedCountryName(for: upper, appLocale: appLocale)
            }
        }
        let rawCode = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if rawCode.count == 2 {
            let upper = rawCode.uppercased()
            if Locale.isoRegionCodes.contains(upper) {
                return localizedCountryName(for: upper, appLocale: appLocale)
            }
        }
        // Не показываем неподтверждённый текст локации (чтобы не вводить в заблуждение).
        return nil
    }

    /// Текущая локация устройства для UI (если удалось безопасно получить ISO-код страны).
    static func localizedCurrentLocationLabel(appLocale: Locale) -> String? {
        guard let code = approximateLocationCountryCode else { return nil }
        return localizedCountryName(for: code, appLocale: appLocale)
    }

    private static func localizedCountryName(for code: String, appLocale: Locale) -> String {
        let upper = code.uppercased()
        let language = LocalizationLanguageResolver.bundleLanguageCodeFromIdentifier(appLocale.identifier)
        let dbName = CountryDatabase.getLocalizedCountryName(for: upper, language: language, fallback: upper)
        if dbName != upper { return dbName }
        if let byAppLocale = appLocale.localizedString(forRegionCode: upper), !byAppLocale.isEmpty {
            return byAppLocale
        }
        if let byAutoupdating = Locale.autoupdatingCurrent.localizedString(forRegionCode: upper), !byAutoupdating.isEmpty {
            return byAutoupdating
        }
        if let byEn = Locale(identifier: "en").localizedString(forRegionCode: upper), !byEn.isEmpty {
            return byEn
        }
        return upper
    }

}
