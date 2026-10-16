import XCTest
import UIKit
import CoreImage
@testable import World_Arena__Flags

@MainActor
final class FlagsExperienceTests: XCTestCase {
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

}
