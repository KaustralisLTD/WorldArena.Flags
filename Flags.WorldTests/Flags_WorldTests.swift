//
//  Flags_WorldTests.swift
//  Flags.WorldTests
//
//  Created by Sergey Shchurenko on 26.02.2025.
//

import Testing
import Foundation
@testable import World_Arena__Flags

struct Flags_WorldTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

struct StreakFreezeTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return c
    }
    private func date(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day))!
    }
    @Test func freezeProtectsOnlyMissedDaysAndNeverToday() {
        let result = StreakFreezePlan.evaluate(from: date(1), until: date(4), stock: 3, active: true,
            calendar: calendar, isPlayed: { $0 == date(2) }, isFrozen: { _ in false })
        #expect(result.remaining == 1)
        #expect(result.protectedDays == [date(1), date(3)])
        #expect(!result.broken)
    }
    @Test func insufficientStockBreaksSeries() {
        let result = StreakFreezePlan.evaluate(from: date(1), until: date(5), stock: 3, active: true,
            calendar: calendar, isPlayed: { _ in false }, isFrozen: { _ in false })
        #expect(result.remaining == 0)
        #expect(result.protectedDays.count == 3)
        #expect(result.broken)
    }
    @Test func alreadyFrozenDaysAreNotChargedAgain() {
        let result = StreakFreezePlan.evaluate(from: date(1), until: date(3), stock: 2, active: true,
            calendar: calendar, isPlayed: { _ in false }, isFrozen: { _ in true })
        #expect(result.remaining == 2)
        #expect(result.protectedDays.isEmpty)
    }
    @Test func brokenSeriesDoesNotWasteNewFreezes() {
        let result = StreakFreezePlan.evaluate(from: date(1), until: date(3), stock: 3, active: false,
            calendar: calendar, isPlayed: { _ in false }, isFrozen: { _ in false })
        #expect(result.remaining == 3)
        #expect(result.broken)
    }
    @Test func daylightSavingUsesCalendarDays() {
        let result = StreakFreezePlan.evaluate(from: date(24), until: date(27), stock: 3, active: true,
            calendar: calendar, isPlayed: { _ in false }, isFrozen: { _ in false })
        #expect(result.protectedDays.count == 3)
        #expect(!result.broken)
    }
}

struct FriendAvatarTests {
    @Test func missingAvatarDoesNotInventCountryFromUsername() throws {
        let user = try #require(FriendFromAPI(from: ["username": "salex"]))
        #expect(user.toFriend().avatar == "person.crop.circle.fill")
        #expect(user.toFriend().displayAvatar != "🇸🇪")
    }

    @Test func chosenAvatarTakesPriorityOverCountry() throws {
        let user = try #require(FriendFromAPI(from: ["username": "player", "countryCode": "SE", "avatar": "🦊"]))
        #expect(user.toFriend().displayAvatar == "🦊")
    }

    @Test func profilePhotoSurvivesMapping() throws {
        let user = try #require(FriendFromAPI(from: ["username": "player", "avatar": "custom_photo", "avatarPhotoBase64": "aGVsbG8="]))
        #expect(user.toFriend().remotePhotoAvatarData == Data("hello".utf8))
    }
}

struct QuizAnswerFitTests {
    @Test func flagOnlyShrinksWhenAnswersNeedTheSpace() {
        let heights: [CGFloat] = Array(repeating: 48, count: 6)
        #expect(QuizAnswerFit.flagHeight(preferred: 240, minimum: 130, available: 650, answerHeights: heights) == 240)
        #expect(QuizAnswerFit.flagHeight(preferred: 240, minimum: 130, available: 528, answerHeights: heights) == 200)
        #expect(QuizAnswerFit.flagHeight(preferred: 240, minimum: 90, available: 400, answerHeights: Array(repeating: 100, count: 8)) == 90)
    }

    @Test func keepsAllWhenTheyFit() {
        #expect(QuizAnswerFit.indices(heights: Array(repeating: 48, count: 8), correctIndex: 7, budget: 500).count == 8)
    }
    @Test func sixFitAndCorrectAnswerAtEndSurvives() {
        let result = QuizAnswerFit.indices(heights: Array(repeating: 48, count: 8), correctIndex: 7, budget: 328)
        #expect(result.count == 6)
        #expect(result.contains(7))
    }
    @Test func longNamesAreMeasuredAndAtLeastTwoChoicesRemain() {
        let result = QuizAnswerFit.indices(heights: [100, 48, 90, 48, 48, 48, 100, 48], correctIndex: 6, budget: 210)
        #expect(result == [0, 6])
        #expect(QuizAnswerFit.indices(heights: [200, 200, 200], correctIndex: 2, budget: 90).count == 2)
    }
}

@MainActor
struct AvatarShopTests {
    @Test func oldAvatarDecodesAndSlotsRemainIndependent() throws {
        let data = try JSONEncoder().encode(AvatarConfiguration.default)
        let old = try JSONDecoder().decode(AvatarConfiguration.self, from: data)
        let jacket = try #require(AvatarShopProduct.catalog.first { $0.id == "jacket_1" })
        let champion = try #require(AvatarShopProduct.catalog.first { $0.id == "champion_jacket" })
        let fire = try #require(AvatarShopProduct.catalog.first { $0.id == "effect_fire" })
        let wearing = champion.applying(to: fire.applying(to: jacket.applying(to: old)))
        #expect(wearing.shopOutfit == "champion_jacket")
        #expect(wearing.shopEffect == "effect_fire")
        #expect(champion.applying(to: wearing, remove: true).shopEffect == "effect_fire")
        #expect(try JSONDecoder().decode(AvatarConfiguration.self, from: JSONEncoder().encode(wearing)) == wearing)
        #expect(AvatarPortraitExporter.jpeg(configuration: wearing)?.isEmpty == false)
    }
    @Test func purchaseIsPersistentAndCannotChargeTwice() {
        let p = UserProfile.shared
        let money = p.fBucks, owned = p.ownedAvatarItems, history = p.fBucksHistory
        defer { p.fBucks = money; p.ownedAvatarItems = owned; p.fBucksHistory = history; p.saveToStorage() }
        p.ownedAvatarItems = []; p.fBucks = 10
        #expect(p.purchaseAvatarItem("jacket_1"))
        #expect(p.fBucks == 0)
        #expect(!p.purchaseAvatarItem("jacket_1"))
        #expect(!p.purchaseAvatarItem("cap_1"))
        #expect(!p.purchaseAvatarItem("unknown"))
        p.reloadFromPersistence()
        #expect(p.ownedAvatarItems == ["jacket_1"])
        #expect(p.fBucks == 0)
    }
}

struct WelcomeLivesTests {
    @Test func bonusEndsExactlyAfterSevenDays() {
        let joined = Date(timeIntervalSince1970: 100000)
        #expect(WelcomeLivesPolicy.isActive(joinedAt: joined, now: joined))
        #expect(WelcomeLivesPolicy.isActive(joinedAt: joined, now: joined.addingTimeInterval(604799)))
        #expect(!WelcomeLivesPolicy.isActive(joinedAt: joined, now: joined.addingTimeInterval(604800)))
        #expect(!WelcomeLivesPolicy.isActive(joinedAt: joined, now: joined.addingTimeInterval(-1)))
    }
    @Test func refillsWaitTenMinutesAndCatchUpWithoutOverflow() {
        #expect(WelcomeLivesPolicy.elapsedRefills(since: 1000, now: 1599) == 0)
        #expect(WelcomeLivesPolicy.elapsedRefills(since: 1000, now: 1600) == 1)
        #expect(WelcomeLivesPolicy.elapsedRefills(since: 1000, now: 2200) == 2)
        #expect(WelcomeLivesPolicy.elapsedRefills(since: 1000, now: 900) == 0)
        #expect(WelcomeLivesPolicy.elapsedRefills(since: 0, now: 9000) == 0)
        #expect(WelcomeLivesPolicy.elapsedRefills(since: 1000, now: 99999999) == 2)
    }
}

struct MotivationalRankingConsistencyTests {
    private func player(xp: Int, games: Int = 100, correct: Int = 500) -> MotivationalRanking.Inputs {
        .init(username: "rank-regression", joinDate: Date(timeIntervalSince1970: 1_700_000_000),
              xp: xp, streak: 10, totalGamesPlayed: games, correctAnswers: correct,
              totalAnswersStored: 700, leagueTierIndex: 2)
    }

    @Test func countryPositionCannotBeWorseThanWorldPosition() {
        for xp in [0, 100, 1_000, 10_000, 100_000, 1_000_000] {
            for games in [0, 1, 100, 3_000] {
                let input = player(xp: xp, games: games)
                let global = MotivationalRanking.worldRank(for: input)
                for country in ["UA", "US", "IN", "CN", "VA", "ZZ"] {
                    let local = MotivationalRanking.countryRank(for: input, countryCode: country)
                    #expect(local >= 1)
                    #expect(local <= global)
                }
            }
        }
    }

    @Test func moreXPImprovesBothPositions() {
        let before = player(xp: 1_000)
        let after = player(xp: 50_000)
        #expect(MotivationalRanking.worldRank(for: after) < MotivationalRanking.worldRank(for: before))
        #expect(MotivationalRanking.countryRank(for: after, countryCode: "UA") < MotivationalRanking.countryRank(for: before, countryCode: "UA"))
        #expect(MotivationalRanking.countryRank(for: after, countryCode: "UA") == MotivationalRanking.countryRank(for: after, countryCode: "ua"))
    }
}

struct LearningAlphabetTests {
    @Test func ukrainianSectionsFollowAlphabet() {
        let letters = ["І", "Є", "А", "Я", "И", "Ї", "Е", "Й", "Г", "Ґ"]
        #expect(letters.sorted { LearningAlphabetOrder.precedes($0, $1, locale: Locale(identifier: "uk")) } == ["А", "Г", "Ґ", "Е", "Є", "И", "І", "Ї", "Й", "Я"])
    }
    @Test func countriesUseTranslatedNames() {
        let names = ["Ісландія", "Італія", "Ірландія", "Іспанія", "Албанія"]
        #expect(names.sorted { LearningAlphabetOrder.precedes($0, $1, locale: Locale(identifier: "uk")) } == ["Албанія", "Ірландія", "Ісландія", "Іспанія", "Італія"])
    }
}
