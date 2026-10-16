import SwiftUI

// MARK: - Filter

enum LearningCountryFilter: String, CaseIterable, Identifiable {
    case all
    case unlearned
    case favorites
    case difficult

    var id: String { rawValue }

    static var chipFilters: [LearningCountryFilter] { [.all, .unlearned, .favorites, .difficult] }
}

// MARK: - Progress logic (как на World Progress Map)

@MainActor
enum LearningCountryProgressLogic {
    /// «Освоено»: достаточно ответов и точность, как mastered на карте.
    static func isMastered(_ p: CountryLearningProgress) -> Bool {
        p.total >= 3 && p.accuracy >= 0.8
    }

    /// «Слабые / сложные»: как weakCountries на карте прогресса.
    static func isWeak(_ p: CountryLearningProgress) -> Bool {
        p.total >= 3 && (p.accuracy < 0.6 || p.wrong > p.correct)
    }

    static func studiedCount(in countries: [CountryInfo], gameState: GameState) -> Int {
        countries.filter { isMastered(gameState.learningProgress(forISO2: $0.code)) }.count
    }

    static func applyFilter(
        _ countries: [CountryInfo],
        filter: LearningCountryFilter,
        gameState: GameState
    ) -> [CountryInfo] {
        switch filter {
        case .all:
            return countries
        case .unlearned:
            return countries.filter { !isMastered(gameState.learningProgress(forISO2: $0.code)) }
        case .favorites:
            return countries.filter { gameState.isLearningFavorite(iso2: $0.code) }
        case .difficult:
            return countries.filter { gameState.isLearningCountryDifficult(iso2: $0.code) }
        }
    }

    static func searchMatches(country: CountryInfo, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        let lang = LocalizationManager.shared.currentBundleLanguageCode
        let effectiveLang = lang.isEmpty ? "en" : lang
        let name = CountryDatabase.getLocalizedCountryName(for: country.code, language: effectiveLang, fallback: country.name)
        let capFallback: String = (effectiveLang == "ru")
            ? country.capital
            : CountryDatabase.getLocalizedCapitalName(for: country.code, language: "en", fallback: country.capital)
        let capital = CountryDatabase.getLocalizedCapitalName(for: country.code, language: effectiveLang, fallback: capFallback)
        return name.lowercased().contains(q) || capital.lowercased().contains(q)
    }
}

// MARK: - Progress summary

struct LearningProgressSummaryView: View {
    let studied: Int
    let total: Int
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        let ratio = total > 0 ? Double(studied) / Double(total) : 0
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(localizationManager.localizedString("learning.progress.label"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text("\(studied)/\(total)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: max(6, geo.size.width * CGFloat(ratio)))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Search

struct LearningSearchBarView: View {
    @Binding var text: String
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            TextField(localizationManager.localizedString("learning.search.placeholder"), text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Chips

struct LearningFiltersChipsView: View {
    @Binding var selected: LearningCountryFilter
    /// В «Все страны» чипы растягиваются на всю ширину; в других местах — горизонтальный скролл.
    var useEqualWidthLayout: Bool = false
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        Group {
            if useEqualWidthLayout {
                HStack(spacing: 8) {
                    ForEach(LearningCountryFilter.chipFilters) { filter in
                        chipButton(filter, compact: true)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 2)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LearningCountryFilter.chipFilters) { filter in
                            chipButton(filter, compact: false)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func chipButton(_ filter: LearningCountryFilter, compact: Bool) -> some View {
        let isOn = selected == filter
        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selected = filter
            }
        } label: {
            Text(title(for: filter))
                .font(.system(size: compact ? 12 : 14, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(compact ? 2 : 1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, compact ? 6 : 14)
                .padding(.vertical, 8)
                .learningChipMaxWidth(compact)
                .foregroundColor(isOn ? .white : .primary)
                .background(
                    Capsule()
                        .fill(isOn ? Color.blue : Color.primary.opacity(0.07))
                )
        }
        .buttonStyle(.plain)
    }

    private func title(for filter: LearningCountryFilter) -> String {
        switch filter {
        case .all: return localizationManager.localizedString("learning.filter.all")
        case .unlearned: return localizationManager.localizedString("learning.filter.unlearned")
        case .favorites: return localizationManager.localizedString("learning.filter.favorites")
        case .difficult: return localizationManager.localizedString("learning.filter.difficult")
        }
    }
}

private extension View {
    @ViewBuilder
    func learningChipMaxWidth(_ compact: Bool) -> some View {
        if compact {
            frame(maxWidth: .infinity)
        } else {
            self
        }
    }
}

// MARK: - Empty state

struct LearningEmptyStateView: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            Text(message)
                .font(.system(size: 15, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.blue.opacity(0.15)))
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .transition(.opacity)
    }
}
