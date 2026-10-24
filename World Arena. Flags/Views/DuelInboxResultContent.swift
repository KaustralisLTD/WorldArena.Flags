import SwiftUI

/// Shared medal treatment keeps results as rich and legible as achievement artwork.
struct DuelOutcomeBadge: View {
    let won: Bool?
    private var accent: Color { won == true ? .yellow : won == false ? Color(red: 0.64, green: 0.72, blue: 0.88) : .cyan }
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size.width
            ZStack {
                Circle().fill(LinearGradient(colors: [accent.opacity(0.48), Color(red: 0.06, green: 0.10, blue: 0.20)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.95), accent, accent.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.045)
                Circle().strokeBorder(accent.opacity(0.5), lineWidth: size * 0.015).padding(size * 0.10)
                Image(systemName: "trophy.fill")
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .top, endPoint: .bottom))
                Image(systemName: "sparkle").font(.system(size: size * 0.13)).foregroundColor(.white)
                    .offset(x: size * 0.27, y: -size * 0.25)
            }
        }.accessibilityHidden(true)
    }
}

struct DuelInboxResultContent: View {
    let item: AppNotificationLogItem
    let openDuels: () -> Void
    @ObservedObject private var language = LocalizationManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    private func tr(_ key: String) -> String { language.localizedString(key) }
    private var detail: AppNotificationLogItem.Details { item.details ?? .init() }
    private var tied: Bool { detail.myScore != nil && detail.myScore == detail.opponentScore }
    private var hasTimes: Bool { detail.myTimeMs != nil && detail.opponentTimeMs != nil }
    private var accent: Color { detail.iWon == true ? .cyan : .orange }
    private func time(_ milliseconds: Int?) -> String {
        guard let milliseconds, milliseconds >= 0 else { return "—" }
        return (Double(milliseconds) / 1000).formatted(.number.locale(Locale(identifier: language.currentBundleLanguageCode)).precision(.fractionLength(2))) + " " + tr("Time seconds unit short")
    }
    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 14) {
                DuelOutcomeBadge(won: detail.iWon).frame(width: 104, height: 104)
                    .shadow(color: accent.opacity(0.3), radius: 24, y: 8)
                    .scaleEffect(appeared ? 1 : 0.94)
                Text(item.displayTitle).font(.system(size: 32, weight: .heavy, design: .rounded))
                if let date = item.date {
                    Text(date.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(Locale(identifier: language.currentBundleLanguageCode))))
                        .font(.caption).foregroundColor(.white.opacity(0.65))
                }
                HStack(spacing: 10) {
                    player(name: tr("You"), score: detail.myScore, milliseconds: detail.myTimeMs, winner: detail.iWon == true)
                    Text(":").font(.title.bold()).foregroundColor(.white.opacity(0.45)).accessibilityHidden(true)
                    player(name: detail.opponentName ?? tr("Duel"), score: detail.opponentScore, milliseconds: detail.opponentTimeMs, winner: detail.iWon == false)
                }.padding(.top, 8)
                if tied && hasTimes {
                    Label(tr("duel.tiebreaker.title"), systemImage: "stopwatch.fill")
                        .font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
                        .padding(14).frame(maxWidth: .infinity)
                        .background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier("inbox.duel.tieReason")
                }
            }
            .foregroundColor(.white).padding(22)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [Color(red: 0.04, green: 0.08, blue: 0.19), Color(red: 0.12, green: 0.11, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 28))
            if !hasTimes {
                Text(tr("inbox.duelTimeUnavailable")).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            Button(action: openDuels) {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text(tr("Duel Summary"))
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.right")
                }.font(.headline).padding(18).frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 18))
            }.buttonStyle(.plain).accessibilityIdentifier("inbox.duel.openSummary")
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(.easeOut(duration: 0.25)) { appeared = true } }
        }
    }
    private func player(name: String, score: Int?, milliseconds: Int?, winner: Bool) -> some View {
        VStack(spacing: 10) {
            Text(name).font(.subheadline.weight(.semibold)).lineLimit(2).frame(height: 38).minimumScaleFactor(0.8)
            Text(score.map(String.init) ?? "—").font(.system(size: 48, weight: .heavy, design: .rounded)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
            Label(time(milliseconds), systemImage: "stopwatch")
                .font(.subheadline.weight(.semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                .foregroundColor(winner ? .cyan : .white.opacity(0.75))
                .accessibilityIdentifier(winner ? "inbox.duel.winnerTime" : "inbox.duel.otherTime")
        }.multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.horizontal, 10).padding(.vertical, 16)
            .background(Color.white.opacity(winner ? 0.10 : 0.045), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(winner ? Color.cyan.opacity(0.65) : Color.white.opacity(0.10), lineWidth: 1))
    }
}
