//
//  Flags_WorldUITests.swift
//  Flags.WorldUITests
//
//  Created by Sergey Shchurenko on 26.02.2025.
//

import XCTest
import StoreKitTest

final class Flags_WorldUITests: XCTestCase {
    @MainActor
    func testLocalizedTenScreenCapture() throws {
        let app = XCUIApplication()
        let names = ["quiz", "duel", "map", "achievements", "quests", "league", "statistics", "country", "regions", "avatars"]
        for language in ["en", "ru", "uk", "de", "fr", "es", "it", "pt-BR"] {
            app.launchArguments = ["UITesting", "StoreCaptureGallery", "StoreMediaCapture", "UITestingNormalText", "-selectedLanguage", language, "-AppleLanguages", "(" + language + ")", "-AppleLocale", language.replacingOccurrences(of: "-", with: "_"), "-AppleInterfaceStyle", "Light"]
            app.launch()
            XCTAssertTrue(app.buttons["capture.next"].waitForExistence(timeout: 30))
            for (index, name) in names.enumerated() {
                sleep(index == 2 ? 4 : 2)
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = "store-" + language + "-" + name; shot.lifetime = .keepAlways; add(shot)
                if index != names.count - 1 { app.buttons["capture.next"].tap() }
            }
            app.terminate()
        }
    }

    @MainActor
    func testOctoberDuelStoreScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingDuelResults", "StoreMediaCapture", "-selectedLanguage", "ru"]
        app.launch(); sleep(2)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "store-duel-final"; shot.lifetime = .keepAlways; add(shot)
    }

    @MainActor
    func testOctoberStoreMedia() throws {
        let app = XCUIApplication()
        for (name, mode) in [("quiz", "UITestingLargeQuiz"), ("duel", "UITestingDuelResults"), ("map", "PremiumCaptureMap"), ("achievements", "AchievementCollectionQA"), ("shop", "StoreCaptureShop")] {
            app.launchArguments = ["UITesting", mode, "StoreMediaCapture", "UITestingNormalText", "-selectedLanguage", "ru", "-AppleInterfaceStyle", "Light"]
            app.launch(); sleep(3)
            if name == "achievements" { app.swipeUp(); app.swipeUp(); app.swipeUp() }
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "store-" + name; shot.lifetime = .keepAlways; add(shot)
            app.terminate()
        }
    }

    @MainActor
    func testDuelNotificationTimesAndSummaryNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "NotificationInboxQA", "-selectedLanguage", "uk", "-AppleInterfaceStyle", "Light"]
        app.launch()
        let result = app.buttons["inbox.item.preview-duel"]
        XCTAssertTrue(result.waitForExistence(timeout: 20))
        let list = XCTAttachment(screenshot: app.screenshot()); list.name = "duel-inbox-medals"; list.lifetime = .keepAlways; add(list)
        result.tap()
        XCTAssertTrue(app.staticTexts["inbox.duel.tieReason"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "41,23")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "43,78")).firstMatch.exists)
        let detail = XCTAttachment(screenshot: app.screenshot()); detail.name = "duel-inbox-time-victory"; detail.lifetime = .keepAlways; add(detail)
        app.terminate()
        app.launchArguments = ["UITesting", "NotificationDuelRoutingQA", "NotificationInboxQA", "-selectedLanguage", "uk"]
        app.launch()
        XCTAssertTrue(result.waitForExistence(timeout: 20)); result.tap()
        let open = app.buttons["inbox.duel.openSummary"]
        XCTAssertTrue(open.waitForExistence(timeout: 5)); open.tap()
        XCTAssertTrue(app.navigationBars["Виклики"].waitForExistence(timeout: 10))
        let destination = XCTAttachment(screenshot: app.screenshot()); destination.name = "duel-inbox-destination"; destination.lifetime = .keepAlways; add(destination)
    }

    @MainActor
    func testAchievementNotificationArtworkScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "NotificationInboxQA", "StoreMediaCapture", "-selectedLanguage", "ru", "-AppleInterfaceStyle", "Light"]
        app.launch()
        let legacy = app.buttons["inbox.item.preview-achievement"]
        XCTAssertTrue(legacy.waitForExistence(timeout: 20))
        let journey = app.buttons["inbox.item.achievement_journey_streak_100"]
        XCTAssertTrue(journey.exists)
        let list = XCTAttachment(screenshot: app.screenshot()); list.name = "achievement-icons-list"; list.lifetime = .keepAlways; add(list)
        legacy.tap()
        XCTAssertTrue(app.buttons["Закрыть"].firstMatch.waitForExistence(timeout: 5))
        let first = XCTAttachment(screenshot: app.screenshot()); first.name = "achievement-icons-original-badge"; first.lifetime = .keepAlways; add(first)
        app.buttons["Закрыть"].firstMatch.tap()
        journey.tap()
        let second = XCTAttachment(screenshot: app.screenshot()); second.name = "achievement-icons-journey-badge"; second.lifetime = .keepAlways; add(second)
    }

    @MainActor
    func testOctoberUpdatesScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "NotificationInboxQA", "-selectedLanguage", "uk"]
        app.launch()
        XCTAssertTrue(app.buttons["inbox.item.preview-duel"].waitForExistence(timeout: 20))
        for id in ["level_100", "league_preview"] {
            let card = app.buttons["inbox.item." + id]
            if !card.isHittable { app.swipeUp() }
            XCTAssertTrue(card.waitForExistence(timeout: 10)); card.tap()
            sleep(1)
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "October " + id; shot.lifetime = .keepAlways; add(shot)
            app.buttons["Закрити"].firstMatch.tap()
        }
        app.terminate()
        app.launchArguments = ["UITesting", "AchievementCollectionQA", "-selectedLanguage", "ru"]
        app.launch(); sleep(2); app.swipeUp(); app.swipeUp(); app.swipeUp()
        let collection = XCTAttachment(screenshot: app.screenshot()); collection.name = "October achievements"; collection.lifetime = .keepAlways; add(collection)
        app.terminate()
        app.launchArguments = ["UITesting", "UITestingDuelResults", "-selectedLanguage", "ru"]
        app.launch(); sleep(2)
        let duel = XCTAttachment(screenshot: app.screenshot()); duel.name = "October duel result"; duel.lifetime = .keepAlways; add(duel)
    }

    @MainActor
    func testNotificationInboxUkrainianAndArabic() throws {
        let app=XCUIApplication()
        for language in ["uk","ar"] {
            app.launchArguments=["UITesting","NotificationInboxQA","-selectedLanguage",language]
            app.launch()
            XCTAssertTrue(app.buttons["inbox.item.preview-duel"].waitForExistence(timeout:20))
            let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Flags notification center " + language;shot.lifetime = .keepAlways;add(shot)
            XCTAssertTrue(app.buttons["inbox.readAll"].exists)
            app.terminate()
        }
    }

    @MainActor
    func testNotificationInboxReadsOnlyOpenedEvent() throws {
        let app=XCUIApplication()
        app.launchArguments=["UITesting","NotificationInboxQA","-selectedLanguage","ru"]
        app.launch()
        let first=app.buttons["inbox.item.preview-duel"]
        XCTAssertTrue(first.waitForExistence(timeout:20))
        XCTAssertTrue(app.buttons["inbox.item.preview-achievement"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Flags notification center Russian";shot.lifetime = .keepAlways;add(shot)
        first.tap()
        XCTAssertTrue(app.buttons["Закрыть"].waitForExistence(timeout:5))
        app.buttons["Закрыть"].firstMatch.tap()
        let unread=app.buttons["Новые"]
        XCTAssertTrue(unread.waitForExistence(timeout:5));unread.tap()
        XCTAssertFalse(app.buttons["inbox.item.preview-duel"].exists)
        XCTAssertTrue(app.buttons["inbox.item.preview-achievement"].exists)
        app.buttons["inbox.readAll"].tap()
        XCTAssertFalse(app.buttons["inbox.item.preview-achievement"].exists)
    }

    @MainActor
    func testAppIconPickerDisplaysLocalizedChoices() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "AppIconQA", "-selectedLanguage", "ru"]
        app.launch()
        XCTAssertTrue(app.buttons["appIcon.choice.ru"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["appIcon.choice.en"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Flags localized app icon selection"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testCaptureLifecycleMapsForThirtyLanguages() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let languages = ["ru","en","uk","de","es","fr","it","pt-BR","nl","pl","ca","cs","el","sv","ro","hu","tr","ar","hi","bn","ta","te","th","vi","id","fil","ja","ko","zh","zh-Hant"]
        for lang in languages {
            let app = XCUIApplication()
            app.launchArguments = ["UITesting", "PremiumCaptureMap", "LifecycleMapCapture", "-selectedLanguage", lang, "-AppleLanguages", "(\(lang))", "-AppleLocale", lang]
            app.launch()
            let map = app.maps.firstMatch
            XCTAssertTrue(map.waitForExistence(timeout: 25), lang)
            let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if lang == "ru" {
                let decline = system.buttons["Ask App Not to Track"]
                if decline.waitForExistence(timeout: 5) { decline.tap() }
            }
            for label in ["Ask App Not to Track", "Don’t Allow", "Don't Allow", "Not Now"] {
                if system.buttons[label].exists { system.buttons[label].tap() }
            }
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Lifecycle-map-" + lang
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.terminate()
        }
    }

    @MainActor
    func testLifecycleBonusQuestionsAndRewardInRussianAndArabic() throws {
        for lang in ["ru", "ar"] {
            let app = XCUIApplication()
            app.launchArguments = ["UITesting", "LifecycleBonusQA", "-selectedLanguage", lang, "-AppleLanguages", "(\(lang))"]
            app.launch()
            for index in 0..<10 {
                let progress = app.staticTexts["lifecycle.bonus.progress"]
                XCTAssertTrue(progress.waitForExistence(timeout: 20))
                XCTAssertEqual(progress.label, "\(index + 1) / 10")
                let answer = app.buttons["lifecycle.answer.FR"]
                XCTAssertTrue(answer.waitForExistence(timeout: 5))
                if !answer.isHittable { app.swipeUp() }
                answer.tap()
            }
            let reward = app.staticTexts["lifecycle.bonus.reward"]
            XCTAssertTrue(reward.waitForExistence(timeout: 10))
            XCTAssertEqual(reward.label, "+2 F-Bucks")
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Lifecycle-bonus-" + lang
            screenshot.lifetime = .keepAlways
            add(screenshot)
            app.terminate()
        }
    }

    @MainActor
    func testDuelNotificationButtons() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingDuelNotification", "-selectedLanguage", "uk"]
        app.launch()
        XCTAssertTrue(app.buttons["duel.invite.accept"].waitForExistence(timeout: 30))
        for (button, result) in [("accept", "Accepted"), ("remind", "Reminded"), ("decline", "Declined")] {
            let target = app.buttons["duel.invite." + button]
            XCTAssertTrue(target.isHittable)
            target.tap()
            XCTAssertEqual(app.staticTexts["duel.qa.action"].label, result)
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "duel-invitation-banner"; shot.lifetime = .keepAlways; add(shot)
    }


    @MainActor
    func testCaptureIPadStoreHome() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        for language in ["en", "ru", "uk"] {
            app.launchArguments = ["-onboarding.hasCompletedFullScreen.v2", "YES", "-guide.completed", "YES", "-guide.pending", "NO", "-selectedLanguage", language, "-AppleLanguages", "(\(language))", "-AppleLocale", language]
            app.launch()
            XCTAssertTrue(app.buttons["home.play"].firstMatch.waitForExistence(timeout: 40))
            Thread.sleep(forTimeInterval: 8)
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            if springboard.alerts.firstMatch.exists { springboard.alerts.firstMatch.buttons.firstMatch.tap() }
            if app.alerts.firstMatch.exists { app.alerts.firstMatch.buttons.firstMatch.tap() }
            Thread.sleep(forTimeInterval: 3)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = language + "-02-home"; shot.lifetime = .keepAlways; add(shot)
            app.terminate()
        }
    }

    @MainActor
    func testCaptureIPadStoreScreens() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        let languages = [("en", ["Quests", "Leagues", "Statistics", "Profile"]),
                         ("ru", ["Квесты", "Лиги", "Статистика", "Профиль"]),
                         ("uk", ["Квести", "Ліги", "Статистика", "Профіль"])]
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = name; shot.lifetime = .keepAlways; add(shot)
        }
        for (language, tabs) in languages {
            let base = ["-onboarding.hasCompletedFullScreen.v2", "YES", "-guide.completed", "YES", "-guide.pending", "NO", "-selectedLanguage", language, "-AppleLanguages", "(\(language))", "-AppleLocale", language]
            app.launchArguments = base
            app.launch()
            let play = app.buttons["home.play"].firstMatch
            XCTAssertTrue(play.waitForExistence(timeout: 40), app.debugDescription)
            Thread.sleep(forTimeInterval: 4)
            capture(language + "-02-home")
            play.tap()
            let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer."))
            if answers.firstMatch.waitForExistence(timeout: 40) {
                Thread.sleep(forTimeInterval: 2)
                capture(language + "-01-quiz")
            }
            app.terminate(); app.launch()
            XCTAssertTrue(app.buttons["home.play"].firstMatch.waitForExistence(timeout: 30))
            for (index, _) in tabs.enumerated() {
                let tab = app.buttons[["calendar", "trophy", "chart.bar", "person"][index]].firstMatch
                XCTAssertTrue(tab.waitForExistence(timeout: 15), app.debugDescription)
                tab.tap(); Thread.sleep(forTimeInterval: 6)
                capture(language + "-0" + String(index + 3) + "-" + ["quests", "leagues", "statistics", "profile"][index])
            }
            app.terminate()
            app.launchArguments = ["PremiumCaptureMap"] + base
            app.launch(); Thread.sleep(forTimeInterval: 15)
            capture(language + "-07-map")
            app.terminate()
            app.launchArguments = ["StoreCaptureShop"] + base
            app.launch(); Thread.sleep(forTimeInterval: 5)
            capture(language + "-08-shop")
            app.terminate()
        }
    }

    @MainActor
    func testCapturePremiumScreens() throws {
        let app = XCUIApplication()
        for screen in ["Map", "Country"] {
            app.launchArguments = ["PremiumCapture" + screen, "-onboarding.hasCompletedFullScreen.v2", "YES", "-selectedLanguage", "en"]
            app.launch()
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 30))
            Thread.sleep(forTimeInterval: 8) // Let remote map tiles and country information finish loading.
            let attachment = XCTAttachment(screenshot: app.scrollViews.firstMatch.screenshot())
            attachment.name = "PremiumCapture" + screen
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }

    @MainActor
    func testFirstFBuckOpensShop() throws {
        let app = XCUIApplication()
        app.launchArguments = ["FBucksRewardQA", "-onboarding.hasCompletedFullScreen.v2", "YES", "-selectedLanguage", "uk", "-education.fbucks.pending", "YES", "-education.fbucks.seen", "NO"]
        app.launch()
        let button = app.buttons["education.fbucks.openShop"]
        XCTAssertTrue(button.waitForExistence(timeout: 20))
        button.tap()
        XCTAssertTrue(app.buttons["shop.item.cap_1"].waitForExistence(timeout: 10))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "First-FBuck-Shop"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCountryNavigationUpdatesImmediatelyAndBackWorks() throws {
        let app = XCUIApplication()
        app.launchArguments = ["LearningCaptureEgypt", "-onboarding.hasCompletedFullScreen.v2", "YES", "-selectedLanguage", "uk"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Єгипет"].waitForExistence(timeout: 20))
        let next = app.buttons["learning.country.next"]
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: next)
        waitForExpectations(timeout: 20)
        next.tap()
        XCTAssertFalse(app.staticTexts["Єгипет"].exists, "Previous country must disappear without a network response")
        app.buttons["learning.country.previous"].tap()
        XCTAssertTrue(app.staticTexts["Єгипет"].exists)
        app.buttons["learning.country.back"].tap()
        XCTAssertTrue(app.staticTexts["learning.qa.root"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLearningCountryScreens() throws {
        let app = XCUIApplication()
        for screen in ["Europe", "Egypt"] {
            app.launchArguments = ["LearningCapture" + screen, "-onboarding.hasCompletedFullScreen.v2", "YES", "-selectedLanguage", "uk"]
            app.launch()
            if screen == "Europe" {
                XCTAssertTrue(app.staticTexts["Албанія"].waitForExistence(timeout: 20))
            } else {
                XCTAssertTrue(app.staticTexts["Єгипет"].waitForExistence(timeout: 20))
                Thread.sleep(forTimeInterval: 5)
                for _ in 0..<5 { app.swipeDown() }
            }
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "Learning-" + screen
            attachment.lifetime = .keepAlways
            add(attachment)
            if screen == "Egypt" {
                for _ in 0..<3 { app.swipeUp() }
                let gallery = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                gallery.name = "Egypt-gallery"
                gallery.lifetime = .keepAlways
                add(gallery)
            }
            app.terminate()
        }
    }

    @MainActor
    func testPremiumLearningStories() throws {
        let app = XCUIApplication()
        app.launchArguments = ["PremiumStoryQA", "-onboarding.hasCompletedFullScreen.v2", "YES", "-selectedLanguage", "ru"]
        app.launch()
        let next = app.buttons["premium.story.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 25))
        XCTAssertTrue(app.staticTexts["Больше практики. Меньше пробелов."].exists)
        next.tap()
        XCTAssertTrue(app.staticTexts["За каждым флагом — история."].waitForExistence(timeout: 3))
        next.tap()
        XCTAssertTrue(app.staticTexts["Знай, что учить дальше."].waitForExistence(timeout: 3))
        app.buttons["premium.story.screenshot"].swipeLeft()
        XCTAssertTrue(app.staticTexts["Видьте свой результат"].waitForExistence(timeout: 3))
        XCTAssertFalse(next.isEnabled)
        app.buttons["premium.story.screenshot"].swipeRight()
        XCTAssertTrue(app.staticTexts["Знай, что учить дальше."].waitForExistence(timeout: 3))
        let more = app.buttons["premium.scroll.more"]
        for _ in 0..<3 where !more.isHittable { app.swipeUp() }
        XCTAssertTrue(more.isHittable)
        more.tap()
        let weekly = app.buttons["premium.benefit.weekly.title"]
        for _ in 0..<5 where !weekly.isHittable { app.swipeUp() }
        XCTAssertTrue(weekly.isHittable)
        XCTAssertFalse(app.staticTexts["premium.benefit.weekly.body"].exists)
        weekly.tap()
        XCTAssertTrue(app.staticTexts["premium.benefit.weekly.body"].waitForExistence(timeout: 3))
        weekly.tap()
        XCTAssertFalse(app.staticTexts["premium.benefit.weekly.body"].exists)
        for _ in 0..<6 where !app.buttons["premium.story.screenshot"].isHittable { app.swipeDown() }
        app.buttons["premium.story.screenshot"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Premium actual progress map"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testFirstRunGuide() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingTour", "-onboarding.hasCompletedFullScreen.v2", "YES", "-selectedLanguage", "en"]
        app.launch()
        let next = app.buttons["guide.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 25))
        for index in 0..<5 {
            Thread.sleep(forTimeInterval: 0.8) // Allow the tab transition and anchor layout to settle.
            XCTAssertTrue(next.isHittable)
            XCTAssertGreaterThanOrEqual(next.frame.minY, app.frame.minY)
            XCTAssertLessThanOrEqual(next.frame.maxY, app.frame.maxY - 20,
                                     "The guide action must remain fully above the home indicator")
            let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            image.name = "Guide step \(index + 1)"; image.lifetime = .keepAlways; add(image)
            next.tap()
        }
        XCTAssertFalse(next.exists)
        app.buttons["Profile"].firstMatch.tap()
        let replay = app.buttons["App guide"]
        for _ in 0..<8 where !replay.isHittable { app.swipeUp() }
        XCTAssertTrue(replay.isHittable)
        replay.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        app.buttons["Skip"].tap()
        XCTAssertFalse(next.exists)
    }

    @MainActor
    func testPremiumLayout() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "PremiumQA", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        defer { session.clearTransactions() }
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingPremium", "-selectedLanguage", "en"]
        app.launch()
        XCTAssertTrue(app.buttons["premium.close"].waitForExistence(timeout: 15))
        let yearly = app.buttons["premium.product.WorldArena.Flags.YearlyPremium2025"]
        XCTAssertTrue(yearly.waitForExistence(timeout: 25))
        XCTAssertTrue(yearly.label.contains("19.99"))
        let trialShown = expectation(for: NSPredicate(format: "label CONTAINS %@", "7 days free"), evaluatedWith: yearly)
        wait(for: [trialShown], timeout: 10)
        for _ in 0..<3 where !yearly.isHittable { app.swipeUp() }
        XCTAssertTrue(yearly.isHittable)
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["premium.close"])
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Premium layout \(orientation.rawValue)"; shot.lifetime = .keepAlways; add(shot)
            XCTAssertTrue(app.buttons["premium.close"].isHittable)
        }
        XCUIDevice.shared.orientation = .portrait
        app.terminate()
        try session.buyProduct(productIdentifier: "WorldArena.Flags.YearlyPremium2025")
        try session.expireSubscription(productIdentifier: "WorldArena.Flags.YearlyPremium2025")
        app.launch()
        XCTAssertTrue(yearly.waitForExistence(timeout: 25))
        XCTAssertFalse(yearly.label.contains("7 days free"))
        let monthly = app.buttons["premium.product.WorldArena.Flags.MonthPremium2025"]
        XCTAssertTrue(monthly.exists)
        XCTAssertTrue(monthly.label.contains("4.00"))
        XCTAssertFalse(monthly.label.contains("7 days free"))
    }

    @MainActor
    func testAvatarShopPreview() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingShop", "-selectedLanguage", "en"]
        app.launch()
        let jacket = app.buttons["shop.item.jacket_1"]
        XCTAssertTrue(jacket.waitForExistence(timeout: 20))
        if !jacket.isHittable { app.swipeUp() }
        jacket.tap()
        XCTAssertTrue(app.buttons["shop.apply"].waitForExistence(timeout: 10))
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "Explorer jacket fitting"; image.lifetime = .keepAlways; add(image)
    }

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
    func testLargeTextDuelResult() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingDuelResults", "-selectedLanguage", "uk", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let next = app.buttons["qa.nextOutcome"]
        XCTAssertTrue(next.waitForExistence(timeout: 15))
        for outcome in ["won", "lost"] {
            XCTAssertTrue(app.otherElements["duel.outcome." + outcome].firstMatch.waitForExistence(timeout: 10))
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Large Ukrainian duel " + outcome; shot.lifetime = .keepAlways; add(shot)
            next.tap()
        }
    }

    @MainActor
    func testBelarusMapBackCardScrolling() throws {
        try checkBelarusMapScrolling(textArgument: "UITestingNormalText")
    }

    @MainActor
    func testBelarusMapBackCardScrollingLargeText() throws {
        try checkBelarusMapScrolling(textArgument: "UITestingExtremeText")
    }

    @MainActor
    private func checkBelarusMapScrolling(textArgument: String) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingLargeQuiz", textArgument, "UITestingBelarusMap",
                               "-selectedLanguage", "ru", "-facts.map", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["qa.flip"].waitForExistence(timeout: 20))
        for cycle in 0..<3 {
            app.buttons["qa.flip"].tap()
            let details = app.scrollViews["quiz.countryDetails"]
            XCTAssertTrue(details.waitForExistence(timeout: 5))
            let start = details.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            let end = details.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
            for _ in 0..<5 {
                start.press(forDuration: 0.05, thenDragTo: end)
                end.press(forDuration: 0.05, thenDragTo: start)
            }
            details.swipeUp()
            let map = app.descendants(matching: .any)["quiz.countryMap"].firstMatch
            XCTAssertTrue(map.exists)
            XCTAssertEqual(app.state, .runningForeground)
            if cycle == 0 {
                let ready = expectation(for: NSPredicate(format: "value == %@", "ready"), evaluatedWith: map)
                wait(for: [ready], timeout: 45)
                let shot = XCTAttachment(screenshot: app.screenshot())
                shot.name = "Belarus map after scrolling"; shot.lifetime = .keepAlways; add(shot)
            }
            app.buttons["qa.flip"].tap()
            XCTAssertFalse(details.exists)
        }
    }

    @MainActor
    func testCountryBoundaryScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingLargeQuiz", "UITestingNormalText",
                               "-selectedLanguage", "ru", "-facts.map", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["qa.flip"].waitForExistence(timeout: 20))
        app.buttons["qa.flip"].tap()
        let details = app.scrollViews["quiz.countryDetails"]
        XCTAssertTrue(details.waitForExistence(timeout: 10))
        details.swipeUp()
        let map = app.descendants(matching: .any)["quiz.countryMap"].firstMatch
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        let ready = expectation(for: NSPredicate(format: "value == %@", "ready"), evaluatedWith: map)
        wait(for: [ready], timeout: 45)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Country facts with highlighted border"; shot.lifetime = .keepAlways; add(shot)
    }

    @MainActor
    func testQuizMapSurvivesTapsAndCardRemoval() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingLargeQuiz", "UITestingNormalText",
                               "-selectedLanguage", "uk", "-facts.map", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["quiz.answer.BRA"].firstMatch.waitForExistence(timeout: 15))
        // Flip repeatedly, including while the asynchronous map image is loading.
        for _ in 0..<3 {
            app.buttons["qa.flip"].tap()
            let details = app.scrollViews["quiz.countryDetails"]
            XCTAssertTrue(details.waitForExistence(timeout: 5))
            details.swipeUp()
            let map = app.descendants(matching: .any)["quiz.countryMap"].firstMatch
            XCTAssertTrue(map.waitForExistence(timeout: 5))
            map.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertEqual(app.state, .runningForeground)
            XCTAssertTrue(details.exists)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer.")).count, 6)
            app.buttons["qa.flip"].tap()
            XCTAssertTrue(app.buttons["quiz.answer.BRA"].firstMatch.exists)
        }
    }

    @MainActor
    func testNormalQuizCardSizing() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingLargeQuiz", "UITestingNormalText", "-selectedLanguage", "uk"]
        app.launch()
        XCTAssertTrue(app.buttons["quiz.answer.BRA"].firstMatch.waitForExistence(timeout: 15))
        sleep(1)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer.")).count, 6)
        let originalFrames = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer.")).allElementsBoundByIndex.map { $0.frame }
        let front = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        front.name = "Normal font full-size flag"; front.lifetime = .keepAlways; add(front)
        app.buttons["qa.flip"].tap()
        let details = app.scrollViews["quiz.countryDetails"]
        XCTAssertTrue(details.waitForExistence(timeout: 5))
        sleep(1)
        XCTAssertGreaterThanOrEqual(details.frame.height, 220)
        XCTAssertLessThan(details.frame.height, 320, "Facts must not stretch to fill the viewport")
        XCTAssertTrue(app.staticTexts["quiz.subregion"].isHittable)
        let remaining = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer.")).allElementsBoundByIndex
        XCTAssertEqual(remaining.count, originalFrames.count)
        for (answer, frame) in zip(remaining, originalFrames) {
            XCTAssertEqual(answer.frame.minY, frame.minY, accuracy: 1)
            XCTAssertFalse(answer.isEnabled)
        }
        let back = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        back.name = "Normal font compact facts"; back.lifetime = .keepAlways; add(back)
    }

    @MainActor
    func testLargeTextQuiz() throws {
        let app = XCUIApplication()
        for extreme in [false, true] {
            app.launchArguments = ["UITesting", "UITestingLargeQuiz", "-selectedLanguage", "uk"] + (extreme ? ["UITestingExtremeText"] : [])
            app.launch()
            let correct = app.buttons["quiz.answer.BRA"].firstMatch
            XCTAssertTrue(correct.waitForExistence(timeout: 15))
            sleep(1)
            let answers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer.")).allElementsBoundByIndex
            XCTAssertGreaterThanOrEqual(answers.count, 2)
            XCTAssertLessThan(answers.count, 8)
            XCTAssertEqual(app.scrollViews.count, 0, "Question answers must not be inside a scroll view")
            for answer in answers {
                XCTAssertTrue(answer.isHittable)
                XCTAssertGreaterThan(answer.frame.minY, 0)
                XCTAssertLessThan(answer.frame.maxY, app.frame.maxY - 20)
            }
            XCTAssertTrue(correct.isHittable)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "All answers visible extreme \(extreme)"; shot.lifetime = .keepAlways; add(shot)
            app.buttons["qa.flip"].tap()
            let details = app.scrollViews["quiz.countryDetails"]
            XCTAssertTrue(details.waitForExistence(timeout: 5))
            sleep(1)
            XCTAssertLessThan(details.frame.maxY, app.frame.maxY - 20)
            let remaining = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer.")).allElementsBoundByIndex
            XCTAssertEqual(remaining.count, answers.count)
            for answer in remaining {
                XCTAssertLessThan(answer.frame.maxY, app.frame.maxY - 20)
                XCTAssertGreaterThanOrEqual(answer.frame.minY, details.frame.maxY)
                XCTAssertFalse(answer.isEnabled)
            }
            if !app.staticTexts["quiz.subregion"].isHittable { details.swipeUp() }
            XCTAssertTrue(app.staticTexts["quiz.subregion"].isHittable)
            let facts = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            facts.name = "Large font facts extreme \(extreme)"; facts.lifetime = .keepAlways; add(facts)
            app.terminate()
        }
    }

    @MainActor
    func testStreakCalendarBothOrientations() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en"]
        app.launch()
        if app.buttons["league.result.continue"].waitForExistence(timeout: 2) { app.buttons["league.result.continue"].tap() }
        let entry = app.buttons["streak.calendar.open"].firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 20))
        entry.tap()
        XCTAssertTrue(app.navigationBars["Streak calendar"].waitForExistence(timeout: 10))
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            sleep(1)
            XCTAssertTrue(app.buttons["streak.calendar.close"].isHittable)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Streak calendar \(orientation.rawValue)"
            shot.lifetime = .keepAlways
            add(shot)
        }
        app.buttons["streak.calendar.close"].tap()
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testHomePlayDescribesNewGame() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en"]
        app.launch()
        let weekly = app.buttons["league.result.continue"]
        if weekly.waitForExistence(timeout: 2) { weekly.tap() }
        let play = app.buttons["home.play"].firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 20))
        XCTAssertEqual(play.label, "Play")
        XCTAssertTrue(play.isHittable)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Home clear play action"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testDuelOutcomeAnimations() throws {
        let app = XCUIApplication()
        for reduced in [false, true] {
            app.launchArguments = ["UITesting", "UITestingDuelResults", "-selectedLanguage", "en"] + (reduced ? ["UITestingReducedMotion"] : [])
            app.launch()
            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = orientation
                for outcome in ["won", "lost", "pending"] {
                    let artwork = app.otherElements["duel.outcome." + outcome].firstMatch
                    XCTAssertTrue(artwork.waitForExistence(timeout: 15))
                    sleep(1)
                    let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                    shot.name = "Duel \(outcome) reduced \(reduced) orientation \(orientation.rawValue)"
                    shot.lifetime = .keepAlways
                    add(shot)
                    XCTAssertFalse(app.otherElements["duel.outcome." + (outcome == "won" ? "lost" : "won")].exists)
                    app.buttons["qa.nextOutcome"].tap()
                }
            }
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testWeeklyResultsArtworkAndDismissal() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingLeagueResult", "-selectedLanguage", "en"]
        app.launch()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            for index in 0..<4 {
                let button = app.buttons["league.result.continue"]
                XCTAssertTrue(button.waitForExistence(timeout: 15))
                if !button.isHittable { app.swipeUp() }
                XCTAssertTrue(button.isHittable)
                let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                shot.name = "Weekly result \(index) orientation \(orientation.rawValue)"
                shot.lifetime = .keepAlways
                add(shot)
                button.tap()
            }
        }
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testProfileTabletBothOrientations() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en"]
        app.launch()
        let profile = app.buttons["Profile"].firstMatch
        XCTAssertTrue(profile.waitForExistence(timeout: 25))
        profile.tap()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            sleep(2) // Allow the system rotation transition to finish before capturing layout.
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "iPad profile \(orientation.rawValue)"
            shot.lifetime = .keepAlways
            add(shot)
            XCTAssertTrue(app.staticTexts["OVERVIEW"].exists)
        }
        XCUIDevice.shared.orientation = .portrait
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
        let initial = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        initial.name = "Quiz redesigned screen"
        initial.lifetime = .keepAlways
        add(initial)
        answers.firstMatch.tap()
        XCTAssertTrue(answers.matching(NSPredicate(format: "value == %@", "Correct")).firstMatch.waitForExistence(timeout: 2))
        let feedback = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
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
        let portraitShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        portraitShot.name = "iPad quiz portrait"
        portraitShot.lifetime = .keepAlways
        add(portraitShot)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.scrollViews["quiz.tablet.landscape"].waitForExistence(timeout: 10))
        for answer in answers.allElementsBoundByIndex {
            XCTAssertTrue(answer.isHittable)
            XCTAssertLessThan(answer.frame.maxY, app.frame.maxY - 20)
        }
        let landscapeShot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscapeShot.name = "iPad quiz landscape"
        landscapeShot.lifetime = .keepAlways
        add(landscapeShot)
        answers.firstMatch.tap()
        XCTAssertTrue(answers.matching(NSPredicate(format: "value == %@", "Correct")).firstMatch.waitForExistence(timeout: 2))
        let feedback = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
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
            let result = app.buttons["league.result.continue"]
            if result.waitForExistence(timeout: 1) { result.tap() }
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
    func testMainMenuBackgroundAndProfileLeagueLink() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-AppleLanguages", "(en)"]
        app.launch()
        XCTAssertTrue(app.buttons["Profile"].firstMatch.waitForExistence(timeout: 30))
        for name in ["Game", "Quests", "Leagues", "Statistics", "Profile"] {
            app.buttons[name].firstMatch.tap()
            let result = app.buttons["league.result.continue"]
            if result.waitForExistence(timeout: 1) { result.tap() }
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Solid menu - \(name)"
            shot.lifetime = .keepAlways
            add(shot)
            XCTAssertTrue(app.tabBars.firstMatch.isHittable)
        }
        let league = app.buttons["profile.league"]
        XCTAssertTrue(league.waitForExistence(timeout: 10))
        league.tap()
        XCTAssertTrue(app.tabBars.buttons["Leagues"].isSelected)
    }

    @MainActor
    func testProfileLargeTextLayout() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let profile = app.buttons["Profile"].firstMatch
        XCTAssertTrue(profile.waitForExistence(timeout: 25))
        profile.tap()
        let name = app.staticTexts["profile.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["profile.settings"].isHittable)
        XCTAssertTrue(app.buttons["profile.avatar"].isHittable)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Profile accessibility text"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["profile.avatar"].tap()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 10), "Avatar opens profile editing")
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
    func testQuickSettingsRegionHighlightPersists() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "StoreMediaCapture", "-selectedLanguage", "uk", "-AppleLanguages", "(uk)", "-AppleLocale", "uk_UA", "-selectedTheme", "dark"]
        app.launch()
        let settings = app.buttons["home.quickSettings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 25))
        func openSettings() {
            for _ in 0..<5 where !settings.isHittable { app.swipeUp() }
            settings.tap()
            XCTAssertTrue(app.buttons["quickSettings.save"].waitForExistence(timeout: 5))
        }
        openSettings()
        let europe = app.buttons["quickSettings.region.Europe"]
        let asia = app.buttons["quickSettings.region.Asia"]
        app.buttons["quickSettings.region.All Regions"].tap()
        europe.tap()
        XCTAssertTrue(europe.isSelected, "Europe must highlight immediately")
        europe.tap()
        XCTAssertTrue(europe.isSelected, "Tapping the selected region must preserve highlighting")
        asia.tap()
        XCTAssertTrue(asia.isSelected)
        XCTAssertTrue(europe.isSelected, "Selecting Asia must retain Europe")
        let africa = app.buttons["quickSettings.region.Africa"]
        africa.tap()
        XCTAssertTrue(africa.isSelected)
        XCTAssertTrue(asia.isSelected)
        XCTAssertTrue(europe.isSelected)
        app.buttons["quickSettings.save"].tap()
        openSettings()
        XCTAssertTrue(europe.isSelected, "Saved regions must highlight when settings reopen")
        XCTAssertTrue(asia.isSelected)
        XCTAssertTrue(africa.isSelected)
        let multiple = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        multiple.name = "three-regions-uk-dark"
        multiple.lifetime = .keepAlways
        add(multiple)
        asia.tap()
        XCTAssertFalse(asia.isSelected)
        XCTAssertTrue(europe.isSelected)
        XCTAssertTrue(africa.isSelected)
        let all = app.buttons["quickSettings.region.All Regions"]
        all.tap()
        XCTAssertTrue(all.isSelected)
        XCTAssertFalse(europe.isSelected)
        XCTAssertFalse(africa.isSelected)
        europe.tap()
        XCTAssertTrue(europe.isSelected)
        XCTAssertFalse(all.isSelected)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "selected-europe-uk-dark"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["quickSettings.cancel"].tap()
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
            XCTAssertLessThan(app.buttons["quickSettings.save"].frame.minY, app.frame.height * 0.25)
            for key in ["Select Region", "Select Level", "Game Mode"] {
                XCTAssertTrue(app.buttons["quickSettings.jump." + key].isHittable)
            }
        }
        func chooseDifficulty(_ name: String) {
            app.buttons["quickSettings.jump.Select Level"].tap()
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
            let bar = app.navigationBars.firstMatch
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
    func testTabletSettingsAndChallengesLayout() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "-selectedLanguage", "en", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let settings = app.buttons["home.quickSettings"]
            XCTAssertTrue(settings.waitForExistence(timeout: 25))
            for _ in 0..<5 where !settings.isHittable { app.swipeUp() }
            settings.tap()
            XCTAssertTrue(app.buttons["quickSettings.save"].waitForExistence(timeout: 5))
            for level in ["easy", "medium", "hard", "expert", "erudite"] {
                XCTAssertTrue(app.buttons["quickSettings.difficulty." + level].isHittable, level + " must be visible without scrolling")
            }
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = orientation == .portrait ? "iPad settings portrait" : "iPad settings landscape"
            shot.lifetime = .keepAlways
            add(shot)
            app.buttons["quickSettings.save"].tap()
            let challenges = app.buttons["home.challenges"]
            for _ in 0..<5 where !challenges.isHittable { app.swipeDown() }
            XCTAssertTrue(challenges.isHittable)
            let home = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            home.name = orientation == .portrait ? "iPad home portrait" : "iPad home landscape"
            home.lifetime = .keepAlways
            add(home)
            challenges.tap()
            XCTAssertTrue(app.navigationBars["Challenges"].waitForExistence(timeout: 5))
            app.buttons["Close"].firstMatch.tap()
        }
    }

    @MainActor
    func testTabletSecondaryPagesBothOrientations() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting", "UITestingTabletPages", "-selectedLanguage", "uk", "-AppleLanguages", "(uk)", "-AppleLocale", "uk_UA"]
        app.launch()
        defer { XCUIDevice.shared.orientation = .portrait }
        let next = app.buttons["qa.nextPage"]
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        for page in 0..<5 {
            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = orientation
                // Let each page finish its staged entrance before recording layout.
                Thread.sleep(forTimeInterval: 3)
                let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                if system.alerts.firstMatch.exists { system.alerts.firstMatch.buttons.firstMatch.tap() }
                XCTAssertTrue(next.isHittable)
                let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                shot.name = "Tablet page \(page) \(orientation.rawValue)"
                shot.lifetime = .keepAlways
                add(shot)
            }
            if page < 4 { next.tap() }
        }
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
