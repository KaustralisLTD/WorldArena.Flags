import SwiftUI
import UIKit

struct AppIconChoice: Identifiable, Equatable {
    let id: String
    let language: String
    let word: String
    var alternateName: String? { id == "en" ? nil : "AppIcon-" + id }
    var previewName: String { id == "en" ? "Logo" : "IconPreview-" + id }
    static func preferred(language: String, systemLanguage: String = Locale.preferredLanguages.first ?? "en") -> AppIconChoice {
        let source = language == "system" || language.isEmpty ? systemLanguage : language
        let base = source.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-").first.map(String.init) ?? "en"
        let code = base == "pt" ? "pt-BR" : base
        return all.first(where: { $0.id == code }) ?? all[0]
    }
    static let all: [AppIconChoice] = [
        .init(id: "en", language: "English", word: "FLAGS"),
        .init(id: "ru", language: "Русский", word: "ФЛАГИ"),
        .init(id: "uk", language: "Українська", word: "ПРАПОРИ"),
        .init(id: "es", language: "Español", word: "BANDERAS"),
        .init(id: "fr", language: "Français", word: "DRAPEAUX"),
        .init(id: "de", language: "Deutsch", word: "FLAGGEN"),
        .init(id: "it", language: "Italiano", word: "BANDIERE"),
        .init(id: "pt-BR", language: "Português", word: "BANDEIRAS")
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
                    Button {
                        UserDefaults.standard.set(false, forKey: "appIcon.manualChoice")
                        changeIcon(to: AppIconChoice.preferred(language: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"), manual: false)
                    } label: {
                        Label(localization.localizedString("appIcon.automatic"), systemImage: "globe")
                    }.disabled(isChanging)
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
                if !UserDefaults.standard.bool(forKey: "appIcon.manualChoice") {
                    let language = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
                    changeIcon(to: AppIconChoice.preferred(language: language), manual: false)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func changeIcon(to choice: AppIconChoice, manual: Bool = true) {
        if UIApplication.shared.alternateIconName == choice.alternateName {
            if manual { UserDefaults.standard.set(true, forKey: "appIcon.manualChoice") }
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
                    UserDefaults.standard.set(true, forKey: "appIcon.manualChoice")
                }
            }
        }
    }
}
