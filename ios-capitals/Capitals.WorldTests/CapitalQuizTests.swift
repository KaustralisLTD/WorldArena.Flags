import XCTest
import UIKit
import CoreImage
@testable import World_Arena__Capitals

@MainActor
final class CapitalQuizTests: XCTestCase {
    func testProfileBannerQRDecodesToCapitalProfileLink() throws {
        let url = ShareService.shared.profileShareURL(verifiedFriendCode: "AB123456")
        XCTAssertEqual(ShareService.shared.profileShareURL(verifiedFriendCode: nil).absoluteString, "https://capital.worldarena.games/")
        let image = ProfileShareBanner.render(username: "Sergii", level: 1, xp: 0, streak: 0, url: url)
        let detector = try XCTUnwrap(CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: nil))
        let ciImage = try XCTUnwrap(CIImage(image: image))
        let codes = detector.features(in: ciImage).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
        XCTAssertEqual(codes, ["https://capital.worldarena.games/profile/AB123456"])
        XCTAssertEqual(image.size, CGSize(width: 1080, height: 1600))
        let attachment = XCTAttachment(image: image)
        attachment.name = "capital-profile-share-banner"
        attachment.lifetime = .keepAlways
        add(attachment)
        let languageCodes = ["ar", "bn", "ca", "cs", "de", "el", "en", "es", "fil", "fr", "hi", "hu", "id", "it", "ja", "ko", "nl", "pl", "pt-BR", "ro", "ru", "sv", "ta", "te", "th", "tr", "uk", "vi", "zh", "zh-Hant"]
        for language in languageCodes {
            let image = ProfileShareBanner.render(username: "Sergii", level: 1, xp: 0, streak: 0, url: url, languageCode: language)
            let codes = detector.features(in: try XCTUnwrap(CIImage(image: image))).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
            XCTAssertEqual(codes, [url.absoluteString], language)
            let attachment = XCTAttachment(image: image)
            attachment.name = "capital-profile-share-banner-\(language)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testEveryPlayableCountryHasAnAttributedOfflineCapitalPhoto() throws {
        let countriesURL = try XCTUnwrap(Bundle.main.url(forResource: "game_countries", withExtension: "json"))
        let countries = try JSONDecoder().decode([Country].self, from: Data(contentsOf: countriesURL))
        let photosURL = try XCTUnwrap(Bundle.main.url(forResource: "capital-photos", withExtension: "json"))
        struct Entry: Decodable {
            let imageName: String
            let capital: String
            let creator: String
            let license: String
            let sourceURL: URL
        }
        let photos = try JSONDecoder().decode([String: Entry].self, from: Data(contentsOf: photosURL))
        for country in countries where !(country.capital ?? []).isEmpty {
            let photo = try XCTUnwrap(photos[country.id], "Missing capital photo: \(country.id)")
            XCTAssertTrue(country.capital?.contains(photo.capital) == true, "Wrong capital: \(country.id)")
            XCTAssertFalse(photo.creator.isEmpty, country.id)
            XCTAssertFalse(photo.license.isEmpty, country.id)
            XCTAssertEqual(photo.sourceURL.scheme, "https")
            let image = try XCTUnwrap(UIImage(named: photo.imageName), "Missing bundled image: \(country.id)")
            XCTAssertGreaterThan(image.size.width, 100)
        }
    }

    func testEverySoloModeLoadsPlayableCapitalQuestions() async throws {
        for mode in [GameState.PlayMode.classic, .timeChallenge, .survival] {
            let game = GameState()
            game.selectedPlayMode = mode
            await game.startNewGame()
            defer { game.stopTimer(); game.stopQuestionTimer() }
            let country = try XCTUnwrap(game.currentFlag)
            XCTAssertFalse(CapitalQuizContent.answer(for: country).isEmpty)
            XCTAssertGreaterThanOrEqual(game.options.count, 2)
            XCTAssertTrue(game.options.contains { $0.id == country.id })
            let answers = game.options.map { CapitalQuizContent.answer(for: $0) }
            XCTAssertFalse(answers.contains(""))
            XCTAssertEqual(Set(answers).count, answers.count)
        }
    }

    private func country(_ id: String, _ capitals: [String]) throws -> Country {
        let data = try JSONSerialization.data(withJSONObject: [
            "cca3": id, "name": ["common": id, "official": id],
            "flags": ["png": "https://flagcdn.com/w320/xx.png"],
            "region": "Europe", "capital": capitals, "population": 1
        ])
        return try JSONDecoder().decode(Country.self, from: data)
    }

    func testSharedCapitalNeverAppearsAsWrongAnswer() throws {
        let correct = try country("AAA", ["Shared capital"])
        let duplicate = try country("BBB", ["Shared capital"])
        let other = try country("CCC", ["Different capital"])
        let options = CapitalQuizContent.uniqueOptions([correct, duplicate, other], correct: correct, pool: [])
        XCTAssertEqual(Set(options.map(\.id)), ["AAA", "CCC"])
    }

    func testMultipleCapitalsArePreserved() throws {
        let correct = try country("AAA", ["First", "Second"])
        XCTAssertEqual(CapitalQuizContent.answer(for: correct), "First / Second")
    }

    func testEmptyCapitalOptionsAreExcludedAndCorrectAnswerRetained() throws {
        let correct = try country("AAA", ["Capital"])
        let empty = try country("BBB", [])
        let options = CapitalQuizContent.uniqueOptions([empty], correct: correct, pool: [])
        XCTAssertEqual(options.map(\.id), ["AAA"])
    }
}
