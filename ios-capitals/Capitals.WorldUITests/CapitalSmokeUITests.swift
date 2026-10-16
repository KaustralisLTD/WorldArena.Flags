import XCTest

final class CapitalSmokeUITests: XCTestCase {
    @MainActor
    func testFirstRunTeachesCapitals() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingOnboarding", "-selectedLanguage", "en", "-AppleLanguages", "(en)"]
        app.launch()
        let paris = app.buttons["onboarding.capital.answer.FR"]
        XCTAssertTrue(paris.waitForExistence(timeout: 30))
        XCTAssertEqual(paris.label, "Paris")
        XCTAssertEqual(app.buttons["onboarding.capital.answer.DE"].label, "Berlin")
        XCTAssertEqual(app.staticTexts["onboarding.capital.country"].label, "France")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "capitals-first-run"; shot.lifetime = .keepAlways; add(shot)
        paris.tap()
        XCTAssertTrue(app.staticTexts["Correct! 🎉"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testNormalGameShowsCapitalAnswers() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-onboarding.hasCompletedFullScreen.v2", "YES", "-guide.completed", "YES", "-guide.pending", "NO", "-selectedLanguage", "en", "-AppleLanguages", "(en)", "-AppleLocale", "en"]
        addUIInterruptionMonitor(withDescription: "Test device permissions") { alert in
            if alert.buttons["Don’t Allow"].exists { alert.buttons["Don’t Allow"].tap(); return true }
            if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
            if alert.buttons["Cancel"].exists { alert.buttons["Cancel"].tap(); return true }
            return false
        }
        app.launch()
        let play = app.buttons["home.play"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 40))
        play.tap()
        let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer."))
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 40))
        XCTAssertGreaterThanOrEqual(answers.count, 4)
        XCTAssertTrue(app.staticTexts["capital.country"].exists)
        XCTAssertTrue(app.otherElements["capital.photo"].exists)
        XCTAssertTrue(app.buttons["Photo source and license"].waitForExistence(timeout: 5))
        let prompt = app.staticTexts["quiz.question"].firstMatch
        XCTAssertTrue(prompt.label.lowercased().contains("capital"), prompt.label)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "capital-normal-game"; screenshot.lifetime = .keepAlways; add(screenshot)
        answers.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["capital.country"].exists)
    }
}
