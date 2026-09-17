import SwiftUI

/// Форматирование длительности дуэли (мс) для отображения: «1:32».
enum DuelDurationFormat {
    static func string(_ ms: Int?) -> String {
        guard let ms, ms >= 0 else { return "—" }
        let totalSec = ms / 1000
        let m = totalSec / 60
        let s = totalSec % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// Ничья по счёту: победитель по меньшему времени — краткий профессиональный блок.
struct DuelTieBreakFootnote: View {
    let challengerName: String
    let opponentName: String
    let challengerTimeMs: Int
    let opponentTimeMs: Int
    let compact: Bool

    @ObservedObject private var localizationManager = LocalizationManager.shared

    init(
        challengerName: String,
        opponentName: String,
        challengerTimeMs: Int,
        opponentTimeMs: Int,
        compact: Bool = false
    ) {
        self.challengerName = challengerName
        self.opponentName = opponentName
        self.challengerTimeMs = challengerTimeMs
        self.opponentTimeMs = opponentTimeMs
        self.compact = compact
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "timer")
                .font(.system(size: compact ? 14 : 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .center)

            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                Text(localizationManager.localizedString("duel.tiebreaker.title"))
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    tieChip(name: challengerName, ms: challengerTimeMs)
                    Text("·")
                        .foregroundColor(.secondary.opacity(0.6))
                    tieChip(name: opponentName, ms: opponentTimeMs)
                }
            }
        }
        .padding(.vertical, compact ? 6 : 8)
        .padding(.horizontal, compact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func tieChip(name: String, ms: Int) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.system(size: compact ? 13 : 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(DuelDurationFormat.string(ms))
                .font(.system(size: compact ? 14 : 15, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
        }
    }
}

/// Строка для сводки истории (времена при равном счёте).
struct DuelHistoryTieTimesLine: View {
    let myTimeMs: Int
    let rivalTimeMs: Int
    var compact: Bool = true

    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .font(.system(size: compact ? 11 : 12, weight: .medium))
                .foregroundColor(.orange.opacity(0.9))
            Text(
                String(
                    format: "%@: %@ · %@: %@",
                    localizationManager.localizedString("You"),
                    DuelDurationFormat.string(myTimeMs),
                    localizationManager.localizedString("Opponent"),
                    DuelDurationFormat.string(rivalTimeMs)
                )
            )
            .font(.system(size: compact ? 12 : 13, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
        }
    }
}
