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
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
