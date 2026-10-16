import SwiftUI
import UIKit

struct AppIconChoice: Identifiable, Equatable {
    let id: String
    let language: String
    let word: String
    var alternateName: String? { id == "en" ? nil : "CapitalIcon_" + id.replacingOccurrences(of: "-", with: "_") }
    var previewName: String { id == "en" ? "Logo" : "CapitalIconPreview_" + id.replacingOccurrences(of: "-", with: "_") }
    static func preferred(language: String, systemLanguage: String = Locale.preferredLanguages.first ?? "en") -> AppIconChoice {
        let source = language == "system" || language.isEmpty ? systemLanguage : language
        let code = LocalizationLanguageResolver.bundleLanguageCodeFromIdentifier(source)
        return all.first(where: { $0.id == code }) ?? all[0]
    }
    static let all: [AppIconChoice] = [
        .init(id: "en", language: "English", word: "CAPITALS"),
        .init(id: "uk", language: "Українська", word: "СТОЛИЦІ"),
        .init(id: "ru", language: "Русский", word: "СТОЛИЦЫ"),
        .init(id: "es", language: "Español", word: "CAPITALES"),
        .init(id: "de", language: "Deutsch", word: "HAUPTSTÄDTE"),
        .init(id: "fr", language: "Français", word: "CAPITALES"),
        .init(id: "it", language: "Italiano", word: "CAPITALI"),
        .init(id: "pt-BR", language: "Português (Brasil)", word: "CAPITAIS"),
        .init(id: "nl", language: "Nederlands", word: "HOOFDSTEDEN"),
        .init(id: "pl", language: "Polski", word: "STOLICE"),
        .init(id: "sv", language: "Svenska", word: "HUVUDSTÄDER"),
        .init(id: "cs", language: "Čeština", word: "HLAVNÍ MĚSTA"),
        .init(id: "ca", language: "Català", word: "CAPITALS"),
        .init(id: "zh", language: "简体中文", word: "首都"),
        .init(id: "zh-Hant", language: "繁體中文", word: "首都"),
        .init(id: "ar", language: "العربية", word: "العواصم"),
        .init(id: "hi", language: "हिन्दी", word: "राजधानियाँ"),
        .init(id: "bn", language: "বাংলা", word: "রাজধানী"),
        .init(id: "ja", language: "日本語", word: "首都"),
        .init(id: "ko", language: "한국어", word: "수도"),
        .init(id: "hu", language: "Magyar", word: "FŐVÁROSOK"),
        .init(id: "vi", language: "Tiếng Việt", word: "THỦ ĐÔ"),
        .init(id: "el", language: "Ελληνικά", word: "ΠΡΩΤΕΥΟΥΣΕΣ"),
        .init(id: "id", language: "Bahasa Indonesia", word: "IBU KOTA"),
        .init(id: "ro", language: "Română", word: "CAPITALE"),
        .init(id: "th", language: "ไทย", word: "เมืองหลวง"),
        .init(id: "ta", language: "தமிழ்", word: "தலைநகரங்கள்"),
        .init(id: "te", language: "తెలుగు", word: "రాజధానులు"),
        .init(id: "tr", language: "Türkçe", word: "BAŞKENTLER"),
        .init(id: "fil", language: "Filipino", word: "MGA KABISERA")
    ]
}

struct AppIconSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedName = UIApplication.shared.alternateIconName
    @State private var isChanging = false
    @State private var showError = false
    private let localization = LocalizationManager.shared

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text(localization.localizedString("appIcon.explanation"))
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Section {
                    ForEach(AppIconChoice.all) { choice in
                        Button {
                            changeIcon(to: choice)
                        } label: {
                            HStack(spacing: 16) {
                                Image(choice.previewName).resizable().scaledToFit()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(choice.language).foregroundColor(.primary)
                                    Text(choice.word).font(.subheadline.bold()).foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedName == choice.alternateName {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                                        .accessibilityLabel(localization.localizedString("appIcon.selected"))
                                }
                            }.padding(.vertical, 4)
                        }
                        .disabled(isChanging || !UIApplication.shared.supportsAlternateIcons)
                        .accessibilityIdentifier("appIcon.choice." + choice.id)
                        .accessibilityValue(selectedName == choice.alternateName ? localization.localizedString("appIcon.selected") : "")
                    }
                }
            }
            .navigationTitle(localization.localizedString("appIcon.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localizedString("Done")) { dismiss() }
                        .disabled(isChanging)
                }
            }
            .alert(localization.localizedString("appIcon.error"), isPresented: $showError) {
                Button("OK", role: .cancel) { }
            }
             .onAppear {
                selectedName = UIApplication.shared.alternateIconName
                if !UserDefaults.standard.bool(forKey: "capitals.appIcon.manualChoice") {
                    let language = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
                    changeIcon(to: AppIconChoice.preferred(language: language), manual: false)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func changeIcon(to choice: AppIconChoice, manual: Bool = true) {
        if UIApplication.shared.alternateIconName == choice.alternateName {
            if manual { UserDefaults.standard.set(true, forKey: "capitals.appIcon.manualChoice") }
            return
        }
        guard !isChanging, UIApplication.shared.supportsAlternateIcons,
              UIApplication.shared.alternateIconName != choice.alternateName else { return }
        isChanging = true
        UIApplication.shared.setAlternateIconName(choice.alternateName) { error in
            DispatchQueue.main.async {
                isChanging = false
                selectedName = UIApplication.shared.alternateIconName
                showError = error != nil
                if error == nil && manual {
                    UserDefaults.standard.set(true, forKey: "capitals.appIcon.manualChoice")
                }
            }
        }
    }
}
