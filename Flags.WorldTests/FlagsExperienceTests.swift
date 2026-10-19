import XCTest
import UIKit
import CoreImage
@testable import World_Arena__Flags

@MainActor
final class FlagsExperienceTests: XCTestCase {
    func testEveryAchievementNotificationResolvesItsOwnCatalogArtwork() {
        for definition in UserProfile.shared.allAchievementDefinitions {
            let structured = AppNotificationLogItem(id: UUID().uuidString, title: "", body: "", date: nil, source: "server", kind: "progress", details: .init(achievementID: definition.id))
            let legacy = AppNotificationLogItem(id: "achievement_" + definition.id, title: "", body: "", date: nil, source: "progress")
            XCTAssertEqual(structured.achievementDefinition?.id, definition.id)
            XCTAssertEqual(legacy.achievementDefinition?.id, definition.id)
            if let asset = definition.imageAssetName { XCTAssertNotNil(UIImage(named: asset), asset) }
            else { XCTAssertNotNil(UIImage(systemName: definition.icon), definition.icon) }
        }
    }

    func testLegacyNotificationTitleAndMilestoneResolveRealAchievement() {
        let legacy = AppNotificationLogItem(id: "old-local-entry", title: "Достижения", body: "Ранняя птица · Достигните серии 5 дней", date: nil, source: "progress")
        XCTAssertEqual(legacy.achievementDefinition?.id, "streak_5")
        let milestone = AppNotificationLogItem(id: "award:server", title: "", body: "", date: nil, source: "server", kind: "progress", details: .init(level: 100))
        XCTAssertEqual(milestone.achievementDefinition?.id, "journey_level_100")
        let unknown = AppNotificationLogItem(id: "achievement_unknown", title: "", body: "", date: nil, source: "progress")
        XCTAssertNil(unknown.achievementDefinition)
        let message = AppNotificationLogItem(id: "message", title: "", body: "Ранняя птица", date: nil, source: "server", kind: "message")
        XCTAssertNil(message.achievementDefinition)
    }

    func testAdditionalAchievementsPreserveExistingCatalog() {
        let definitions = UserProfile.shared.allAchievementDefinitions
        let old = Set(["streak_5", "streak_10", "streak_30", "xp_1000", "xp_5000", "xp_10000", "games_20", "games_100", "acc_70", "acc_85", "league_silver", "league_gold", "league_platinum", "league_diamond", "league_master", "friends_1", "friends_5", "share_1", "games_10_day", "xp_30000"])
        XCTAssertTrue(old.isSubset(of: Set(definitions.map(\.id))))
        XCTAssertEqual(definitions.count, Set(definitions.map(\.id)).count)
        XCTAssertEqual(definitions.filter { $0.id.hasPrefix("journey_") }.count, 12)
        XCTAssertTrue(definitions.contains { $0.id == "journey_level_100" })
    }

    func testEmailAndLocalMilestoneUseSameInboxIdentity() {
        let local = AppNotificationLogItem(id: "level_100", title: "100", body: "", date: nil, source: "progress", kind: "progress")
        let remote = AppNotificationLogItem(id: "award:server-id", title: "100", body: "", date: nil, source: "server", kind: "progress", details: .init(level: 100, xp: 99000))
        XCTAssertEqual(local.deduplicationKey, remote.deduplicationKey)
        let week = AppNotificationLogItem(id: "award:week", title: "League", body: "", date: nil, source: "server", kind: "progress", details: .init(rank: 2, participants: 20, week: "2026-W42"))
        XCTAssertEqual(week.deduplicationKey, "league_2026-W42")
    }

    func testUkrainianOwnershipErrorIsTranslated() {
        let saved = UserDefaults.standard.string(forKey: "selectedLanguage")
        defer { UserDefaults.standard.set(saved, forKey: "selectedLanguage") }
        UserDefaults.standard.set("uk", forKey: "selectedLanguage")
        let error = DuelAPIError.serverError("{\"error\":\"Not your challenge\"}")
        XCTAssertTrue(error.localizedDescription.contains("Цей виклик"))
        XCTAssertFalse(error.localizedDescription.contains("Not your challenge"))
    }

    func testProfileQRDecodesForEverySupportedLanguage() throws {
        let languages = ["ar","bn","ca","cs","de","el","en","es","fil","fr","hi","hu","id","it","ja","ko","nl","pl","pt-BR","ro","ru","sv","ta","te","th","tr","uk","vi","zh","zh-Hant"]
        let url = ShareService.shared.profileURL(username: "AB123456")
        for language in languages {
            let image = ProfileShareBanner.render(username: "Sergii", level: 12, xp: 4800, streak: 14, url: url, languageCode: language)
            XCTAssertEqual(image.size, CGSize(width: 1080, height: 1600))
            let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode,
                context: CIContext(options: [.useSoftwareRenderer: true]),
                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
            let features = detector.features(in: CIImage(cgImage: try XCTUnwrap(image.cgImage)))
            XCTAssertEqual((features.first as? CIQRCodeFeature)?.messageString, url.absoluteString, language)
            if ["en", "ru", "ar"].contains(language) {
                let attachment = XCTAttachment(image: image)
                attachment.name = "Flags-profile-" + language
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    func testProfileLinksEscapeUsernamesWithoutChangingRoute() {
        let url = ShareService.shared.profileURL(username: "Игрок /?#")
        XCTAssertEqual(url.host, "flags.worldarena.games")
        XCTAssertNil(url.query)
        XCTAssertNil(url.fragment)
        XCTAssertTrue(url.absoluteString.contains("%2F%3F%23"))
    }

    func testOpeningNotificationSettingsPreservesSavedTime() {
        let defaults = UserDefaults(suiteName: "flags.reminder.test")!
        defer { defaults.removePersistentDomain(forName: "flags.reminder.test") }
        let saved = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(saved, forKey: "reminderTime")
        let now = saved.addingTimeInterval(123456)
        XCTAssertEqual(NotificationService.savedReminderTime(defaults: defaults, now: now), saved)
        XCTAssertEqual(defaults.object(forKey: "reminderTime") as? Date, saved)
    }

    func testSetupSurvivesRelaunchIncludingPlayMode() {
        let key = "game.classic.setup.prefs.v1"
        let defaults = UserDefaults.standard
        let original = defaults.data(forKey: key)
        defer { if let original { defaults.set(original, forKey: key) } else { defaults.removeObject(forKey: key) } }
        let first = GameState()
        first.selectedRegions = [.europe]
        first.selectedDifficulty = .hard
        first.selectedPlayMode = .survival
        let restored = GameState()
        XCTAssertEqual(restored.selectedRegions, [.europe])
        XCTAssertEqual(restored.selectedDifficulty, .hard)
        XCTAssertEqual(restored.selectedPlayMode, .survival)
    }
    func testLifecycleOutboxSurvivesRelaunchAndAcknowledgesOnlyItsAccount() {
        let defaults = UserDefaults(suiteName: "flags.lifecycle.outbox.test")!
        defer { defaults.removePersistentDomain(forName: "flags.lifecycle.outbox.test") }
        let store = LifecycleEventOutbox(defaults: defaults)
        let now = Date()
        func event(_ id: String) -> LifecycleService.Event {
            .init(id: id, type: "game_completed", at: Int64(now.timeIntervalSince1970 * 1000), timezone: "Europe/Madrid", answers: 10, correct: 8, mode: "classic", difficulty: "easy", region: "Europe", questions: [])
        }
        store.append(event("first"), owner: "alice")
        store.append(event("first"), owner: "alice")
        store.append(event("first"), owner: "bob")
        let restored = LifecycleEventOutbox(defaults: defaults)
        XCTAssertEqual(restored.load(owner: "alice").count, 1)
        // A second game finishes while the first upload is awaiting a response.
        restored.append(event("second"), owner: "alice")
        XCTAssertEqual(restored.acknowledge(["first"], owner: "alice").map(\.id), ["second"])
        XCTAssertEqual(restored.load(owner: "bob").map(\.id), ["first"])
        XCTAssertEqual(restored.acknowledge(["first"], owner: "alice").map(\.id), ["second"])
    }

    func testLifecycleOutboxReadsEventsFromBeforeLearningSnapshotsWereAdded() throws {
        let defaults = UserDefaults(suiteName: "flags.lifecycle.migration.test")!
        defer { defaults.removePersistentDomain(forName: "flags.lifecycle.migration.test") }
        let oldEvent = Data(#"[{"id":"old-session","type":"game_completed","at":1780000000000,"timezone":"UTC","answers":10,"correct":8,"mode":"classic","difficulty":"easy","region":"Europe","questions":[]}]"#.utf8)
        defaults.set(oldEvent, forKey: "lifecycle.outbox.v1.alice")
        let saved = LifecycleEventOutbox(defaults: defaults).load(owner: "alice")
        XCTAssertEqual(saved.first?.id, "old-session")
        XCTAssertNil(saved.first?.weakCountries)
        XCTAssertNil(saved.first?.masteredCountries)
    }

    func testAlternateIconsAreRegisteredForPhoneAndPad() throws {
        let choices = AppIconChoice.all
        XCTAssertEqual(choices.count, 8)
        XCTAssertNil(choices.first?.alternateName)
        // Installed simulator apps are thinned for the current device family.
        let keys = UIDevice.current.userInterfaceIdiom == .pad ? ["CFBundleIcons~ipad"] : ["CFBundleIcons"]
        for key in keys {
            let icons = try XCTUnwrap(Bundle.main.infoDictionary?[key] as? [String: Any], key)
            let alternate = try XCTUnwrap(icons["CFBundleAlternateIcons"] as? [String: Any], key)
            for choice in choices.dropFirst() {
                XCTAssertNotNil(alternate[choice.alternateName!], choice.id)
                XCTAssertNotNil(UIImage(named: choice.previewName), choice.id)
            }
        }
    }

    func testIconDefaultsFollowAppLanguageWithEnglishFallback() {
        XCTAssertEqual(AppIconChoice.preferred(language: "ru").id, "ru")
        XCTAssertEqual(AppIconChoice.preferred(language: "uk-UA").id, "uk")
        XCTAssertEqual(AppIconChoice.preferred(language: "pt_PT").id, "pt-BR")
        XCTAssertEqual(AppIconChoice.preferred(language: "system", systemLanguage: "fr-CA").id, "fr")
        XCTAssertEqual(AppIconChoice.preferred(language: "ja").id, "en")
    }

    func testAcceptedDuelNeverReturnsAsANewInvitation() {
        let id = "accepted-invite-test-" + UUID().uuidString
        defer { UserDefaults.standard.removeObject(forKey: "duelInvite.accepted." + id) }
        XCTAssertFalse(DuelInviteSuppression.isSuppressed(id))
        DuelInviteSuppression.markAccepted(id)
        XCTAssertTrue(DuelInviteSuppression.isSuppressed(id))
        DuelInviteSuppression.clear(id)
        XCTAssertTrue(DuelInviteSuppression.isSuppressed(id), "Clearing a snooze must not restore an accepted invite")
    }

    func testFinishedDuelErrorsAreNotClassifiedAsServerOutages() {
        for message in ["Challenge already completed", "Challenge expired", "Challenge declined", "Opponent already submitted", "Challenge not found"] {
            let payload = String(data: try! JSONSerialization.data(withJSONObject: ["error": message]), encoding: .utf8)!
            XCTAssertTrue(DuelAPIError.serverError(payload).isUnavailableChallenge)
        }
        XCTAssertFalse(DuelAPIError.serverError("upstream unavailable").isUnavailableChallenge)
    }

}
