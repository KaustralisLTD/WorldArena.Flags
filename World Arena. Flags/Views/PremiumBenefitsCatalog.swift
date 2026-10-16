import SwiftUI

/// One verified feature list shared by purchase, benefits and subscription screens.
enum PremiumBenefitsCatalog {
    struct Benefit: Identifiable {
        let id: String
        let icon: String
        var titleKey: String { "premium.benefit.\(id).title" }
        var subtitleKey: String { "premium.benefit.\(id).body" }
    }
    static let all: [Benefit] = [
        Benefit(id: "lives", icon: "heart.fill"),
        Benefit(id: "map", icon: "globe.europe.africa.fill"),
        Benefit(id: "countries", icon: "rectangle.stack.fill"),
        Benefit(id: "anthems", icon: "music.note"),
        Benefit(id: "learning", icon: "book.fill"),
        Benefit(id: "mistakes", icon: "exclamationmark.bubble.fill"),
        Benefit(id: "erudite", icon: "brain.head.profile"),
        Benefit(id: "avatar", icon: "person.crop.circle.badge.checkmark"),
        Benefit(id: "weekly", icon: "gift.fill"),
    ]
}

struct PremiumFamilyBanner: View {
    var onDarkBackground = false
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.title2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(localization.localizedString("premium.family.title"))
                    .font(.headline)
                Text(localization.localizedString("premium.family.body"))
                    .font(.subheadline)
                    .opacity(0.85)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(onDarkBackground ? .white : .primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(onDarkBackground ? Color.white.opacity(0.1) : Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("premium.family")
    }
}
