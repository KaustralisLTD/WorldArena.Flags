import SwiftUI
import UIKit

@MainActor
final class LocalizedAppIcon: ObservableObject {
    static let shared = LocalizedAppIcon()
    @Published var suggestion: AppIconChoice?
    private var changing = false
    private var failedLanguage: String?
    func synchronize() {
        #if targetEnvironment(simulator)
        if CommandLine.arguments.contains("StoreMediaCapture") { return }
        #endif
        if UserDefaults.standard.bool(forKey: "appIcon.manualChoice") { suggestion = nil; return }
        guard !changing, UIApplication.shared.applicationState == .active else { return }
        let code = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        let choice = AppIconChoice.preferred(language: code)
        guard UIApplication.shared.alternateIconName != choice.alternateName else { suggestion = nil; return }
        guard failedLanguage != choice.id else { return }
        guard UIApplication.shared.supportsAlternateIcons else { suggestion = choice; failedLanguage = choice.id; return }
        changing = true
        UIApplication.shared.setAlternateIconName(choice.alternateName) { error in
            Task { @MainActor in
                self.changing = false
                if error != nil { self.failedLanguage = choice.id; self.suggestion = choice }
                else { self.failedLanguage = nil; self.suggestion = nil }
            }
        }
    }
}

struct LocalizedAppIconBanner: View {
    @ObservedObject private var icons = LocalizedAppIcon.shared
    @State private var showPicker = false
    private let lm = LocalizationManager.shared
    var body: some View {
        Group {
            if let choice = icons.suggestion {
                HStack(spacing: 12) {
                    Image(UIApplication.shared.alternateIconName == nil ? "Logo" : "IconPreview-" + (UIApplication.shared.alternateIconName?.replacingOccurrences(of: "AppIcon-", with: "") ?? "en"))
                        .resizable().frame(width: 42, height: 42).clipShape(RoundedRectangle(cornerRadius: 10))
                    Image(systemName: "arrow.right").foregroundColor(.secondary)
                    Image(choice.previewName).resizable().frame(width: 42, height: 42).clipShape(RoundedRectangle(cornerRadius: 10))
                    Button { showPicker = true } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(lm.localizedString("appIcon.suggestion")).font(.subheadline.bold())
                            Text(choice.word + " · " + lm.localizedString("appIcon.choose")).font(.caption)
                        }
                    }
                    Spacer(minLength: 0)
                    Button { icons.suggestion = nil } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel(lm.localizedString("Close"))
                }.padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
            }
        }.sheet(isPresented: $showPicker) { AppIconSelectionView().onDisappear { icons.synchronize() } }
    }
}
