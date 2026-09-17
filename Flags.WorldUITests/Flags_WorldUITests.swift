//
//  Flags_WorldUITests.swift
//  Flags.WorldUITests
//
//  Created by Sergey Shchurenko on 26.02.2025.
//

import XCTest

final class Flags_WorldUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launchEnvironment = ["ENV": "TEST"]
        app.launch()
        
        // Добавляем задержку для стабильности теста
        sleep(2)
        
        // Проверяем наличие основных элементов
        XCTAssertTrue(app.staticTexts["World Flags"].exists, "Заголовок должен существовать")
        
        // Проверяем кнопку старта
        let startButton = app.buttons["START GAME"]
        XCTAssertTrue(startButton.exists, "Кнопка старта должна существовать")
    }

    @MainActor
    func testQuizScreenLayoutAndAnswerFeedback() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let continueButton = app.buttons["Continue"].firstMatch
        XCTAssertTrue(continueButton.waitForExistence(timeout: 20), app.debugDescription)
        continueButton.tap()
        let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer."))
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertGreaterThanOrEqual(answers.count, 4)
        for answer in answers.allElementsBoundByIndex {
            XCTAssertTrue(answer.isHittable, "Answer must be reachable: " + answer.label)
            XCTAssertGreaterThanOrEqual(answer.frame.height, 44)
            XCTAssertLessThanOrEqual(answer.frame.maxY, app.frame.maxY - 20)
        }
        let initial = XCTAttachment(screenshot: app.screenshot())
        initial.name = "Quiz redesigned screen"
        initial.lifetime = .keepAlways
        add(initial)
        answers.firstMatch.tap()
        XCTAssertTrue(answers.matching(NSPredicate(format: "value == %@", "Correct")).firstMatch.waitForExistence(timeout: 2))
        let feedback = XCTAttachment(screenshot: app.screenshot())
        feedback.name = "Quiz answer feedback"
        feedback.lifetime = .keepAlways
        add(feedback)
    }

    @MainActor
    func testTabletQuizPortraitAndLandscape() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let start = app.buttons["Continue"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 25), app.debugDescription)
        start.tap()
        let portrait = app.scrollViews["quiz.tablet.portrait"]
        XCTAssertTrue(portrait.waitForExistence(timeout: 30), app.debugDescription)
        let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer."))
        XCTAssertTrue(answers.firstMatch.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(answers.count, 4)
        for answer in answers.allElementsBoundByIndex {
            XCTAssertTrue(answer.isHittable)
            XCTAssertGreaterThanOrEqual(answer.frame.height, 60)
            XCTAssertLessThan(answer.frame.maxY, app.frame.maxY - 20)
        }
        let portraitShot = XCTAttachment(screenshot: app.screenshot())
        portraitShot.name = "iPad quiz portrait"
        portraitShot.lifetime = .keepAlways
        add(portraitShot)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.scrollViews["quiz.tablet.landscape"].waitForExistence(timeout: 10))
        for answer in answers.allElementsBoundByIndex {
            XCTAssertTrue(answer.isHittable)
            XCTAssertLessThan(answer.frame.maxY, app.frame.maxY - 20)
        }
        let landscapeShot = XCTAttachment(screenshot: app.screenshot())
        landscapeShot.name = "iPad quiz landscape"
        landscapeShot.lifetime = .keepAlways
        add(landscapeShot)
        answers.firstMatch.tap()
        XCTAssertTrue(answers.matching(NSPredicate(format: "value == %@", "Correct")).firstMatch.waitForExistence(timeout: 2))
        let feedback = XCTAttachment(screenshot: app.screenshot())
        feedback.name = "iPad quiz answer feedback"
        feedback.lifetime = .keepAlways
        add(feedback)
    }

    @MainActor
    func testPhoneProfileHeaderAfterTabSwitches() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let profile = app.buttons["Profile"].firstMatch
        XCTAssertTrue(profile.waitForExistence(timeout: 25))
        for tabName in ["Statistics", "Leagues", "Profile"] {
            app.buttons[tabName].firstMatch.tap()
        }
        let name = app.descendants(matching: .any)["profile.name"].firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertLessThan(name.frame.minY, 250)
        let joined = app.staticTexts["profile.joinDate"]
        XCTAssertTrue(joined.isHittable)
        XCTAssertLessThan(joined.frame.maxY, 350)
        XCTAssertTrue(app.buttons["profile.settings"].isHittable)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Profile corrected header"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["Game"].firstMatch.tap()
        profile.tap()
        XCTAssertLessThan(name.frame.minY, 250)
    }

    @MainActor
    func testLeaguesResponsiveLayout() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let tab = app.buttons["Leagues"].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 25))
        tab.tap()
        let title = app.staticTexts["leagues.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        let position = app.buttons["leagues.myPosition"]
        XCTAssertTrue(position.waitForExistence(timeout: 5))
        XCTAssertTrue(position.isHittable)
        let portrait = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        portrait.name = "Leagues portrait"
        portrait.lifetime = .keepAlways
        add(portrait)
        position.tap()
        let player = app.descendants(matching: .any)["leagues.currentUser"].firstMatch
        XCTAssertTrue(player.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(player.isHittable)
        XCUIDevice.shared.orientation = .landscapeLeft
        let scroll = app.scrollViews["leagues.scroll"]
        for _ in 0..<8 where !title.isHittable { scroll.swipeDown() }
        XCTAssertTrue(title.isHittable)
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Leagues landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
    }

    @MainActor
    func testStatisticsResponsiveLayout() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let tab = app.buttons["Statistics"].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 25), app.debugDescription)
        tab.tap()
        let title = app.staticTexts["statistics.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        let first = app.staticTexts["statistics.metric.games"]
        XCTAssertTrue(first.exists, app.debugDescription)
        XCTAssertGreaterThan(first.frame.minY, title.frame.maxY)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Statistics portrait"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let clear = app.buttons["statistics.clear"]
        for _ in 0..<6 where !clear.isHittable { app.scrollViews["statistics.scroll"].swipeUp() }
        XCTAssertTrue(clear.isHittable)
        XCTAssertTrue(app.buttons["statistics.share"].isHittable)
        clear.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        app.alerts.buttons["Cancel"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        let scroll = app.scrollViews["statistics.scroll"]
        for _ in 0..<5 where !title.isHittable { scroll.swipeDown() }
        XCTAssertTrue(title.isHittable)
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Statistics landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
        for _ in 0..<6 where !clear.isHittable { scroll.swipeUp() }
        XCTAssertTrue(clear.isHittable)
        XCTAssertTrue(app.buttons["statistics.share"].isHittable)
    }

    @MainActor
    func testQuickSettingsSaveAndSwipeDismissal() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let settings = app.buttons["home.quickSettings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 25), app.debugDescription)
        func openSettings() {
            for _ in 0..<5 where !settings.isHittable { app.swipeUp() }
            settings.tap()
            XCTAssertTrue(app.buttons["quickSettings.save"].waitForExistence(timeout: 5))
        }
        func chooseDifficulty(_ name: String) {
            let choice = app.buttons["quickSettings.difficulty." + name]
            for _ in 0..<5 where !choice.isHittable { app.scrollViews["quickSettings.content"].swipeUp() }
            XCTAssertTrue(choice.isHittable)
            choice.tap()
            XCTAssertTrue(app.buttons["quickSettings.save"].isHittable, "Save must remain visible while content scrolls")
        }
        openSettings()
        let europe = app.buttons["quickSettings.region.Europe"]
        XCTAssertTrue(europe.waitForExistence(timeout: 5))
        europe.tap()
        chooseDifficulty("easy")
        app.buttons["quickSettings.save"].tap()
        XCTAssertTrue(settings.label.contains("Easy"), settings.label)
        XCTAssertTrue(settings.label.contains("Europe"), settings.label)

        openSettings()
        chooseDifficulty("hard")
        for _ in 0..<3 where app.buttons["quickSettings.save"].exists {
            let bar = app.navigationBars["Game settings"]
            bar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        }
        XCTAssertFalse(app.buttons["quickSettings.save"].exists, "Swiping down must dismiss settings")
        XCTAssertTrue(settings.label.contains("Hard"), settings.label)
        openSettings()
        chooseDifficulty("medium")
        app.buttons["quickSettings.cancel"].tap()
        XCTAssertTrue(settings.label.contains("Hard"), "Cancel must preserve the saved selection")
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
