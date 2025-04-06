//
//  Flags_WorldUITestsLaunchTests.swift
//  Flags.WorldUITests
//
//  Created by Sergey Shchurenko on 26.02.2025.
//

import XCTest

final class Flags_WorldUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launch()
        
        // Проверка, что приложение запустилось успешно
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5), "Приложение должно быть запущено")
        
        // Проверка основных элементов на экране запуска
        XCTAssertTrue(app.staticTexts["World Flags"].exists, "Должен отображаться заголовок приложения")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
