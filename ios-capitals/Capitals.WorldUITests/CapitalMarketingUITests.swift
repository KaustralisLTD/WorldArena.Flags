import XCTest

final class CapitalMarketingUITests: XCTestCase {
    @MainActor func testCaptureAllLocalizedStoreScreens() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let labels = try JSONDecoder().decode([String: [String: String]].self, from: Data(#"""
{"en": {"Игра": "Game", "Профиль": "Profile", "Статистика": "Statistics", "Язык игры": "Game Language", "Выберите язык игры": "Choose game language"}, "ru": {"Игра": "Игра", "Профиль": "Профиль", "Статистика": "Статистика", "Язык игры": "Язык игры", "Выберите язык игры": "Выберите язык игры"}, "uk": {"Игра": "Гра", "Профиль": "Профіль", "Статистика": "Статистика", "Язык игры": "Мова гри", "Выберите язык игры": "Оберіть мову гри"}, "es": {"Игра": "Jugar", "Профиль": "Perfil", "Статистика": "Estadísticas", "Язык игры": "Idioma del juego", "Выберите язык игры": "Elegir idioma del juego"}, "fr": {"Игра": "Jeu", "Профиль": "Profil", "Статистика": "Statistiques", "Язык игры": "Langage du jeu", "Выберите язык игры": "Choisissez la langue du jeu"}, "de": {"Игра": "Spiel", "Профиль": "Profil", "Статистика": "Statistiken", "Язык игры": "Spielsprache", "Выберите язык игры": "Wählen Sie die Spielsprache"}, "it": {"Игра": "Gioco", "Профиль": "Profilo", "Статистика": "Statistiche", "Язык игры": "Linguaggio del gioco", "Выберите язык игры": "Scegli la lingua del gioco"}, "pt-BR": {"Игра": "Jogo", "Профиль": "Perfil", "Статистика": "Estatísticas", "Язык игры": "Linguagem do jogo", "Выберите язык игры": "Escolha o idioma do jogo"}, "nl": {"Игра": "Spel", "Профиль": "Profiel", "Статистика": "Statistieken", "Язык игры": "Speltaal", "Выберите язык игры": "Kies speltaal"}, "pl": {"Игра": "Gra", "Профиль": "Profil", "Статистика": "Statystyka", "Язык игры": "Język gry", "Выберите язык игры": "Wybierz język gry"}, "sv": {"Игра": "Spel", "Профиль": "Profil", "Статистика": "Statistik", "Язык игры": "Spelspråk", "Выберите язык игры": "Välj spelspråk"}, "cs": {"Игра": "Hra", "Профиль": "Profil", "Статистика": "Statistika", "Язык игры": "Herní jazyk", "Выберите язык игры": "Vyberte jazyk hry"}, "ca": {"Игра": "Jugar", "Профиль": "Perfil", "Статистика": "Estadístiques", "Язык игры": "Idioma del joc", "Выберите язык игры": "Triar idioma del joc"}, "zh": {"Игра": "游戏", "Профиль": "个人资料", "Статистика": "统计", "Язык игры": "游戏语言", "Выберите язык игры": "选择游戏语言"}, "zh-Hant": {"Игра": "遊戲", "Профиль": "輪廓", "Статистика": "統計數據", "Язык игры": "遊戲語言", "Выберите язык игры": "選擇遊戲語言"}, "ar": {"Игра": "لعبة", "Профиль": "حساب تعريفي", "Статистика": "إحصائيات", "Язык игры": "لغة اللعبة", "Выберите язык игры": "اختر لغة اللعبة"}, "hi": {"Игра": "खेल", "Профиль": "प्रोफ़ाइल", "Статистика": "आंकड़े", "Язык игры": "खेल भाषा", "Выберите язык игры": "खेल की भाषा चुनें"}, "bn": {"Игра": "খেলা", "Профиль": "প্রোফাইল", "Статистика": "পরিসংখ্যান", "Язык игры": "খেলার ভাষা", "Выберите язык игры": "গেমের ভাষা বেছে নিন"}, "ja": {"Игра": "ゲーム", "Профиль": "プロフィール", "Статистика": "統計", "Язык игры": "ゲーム言語", "Выберите язык игры": "ゲーム言語を選択してください"}, "ko": {"Игра": "게임", "Профиль": "윤곽", "Статистика": "통계", "Язык игры": "게임 언어", "Выберите язык игры": "게임 언어 선택"}, "hu": {"Игра": "Játék", "Профиль": "Profil", "Статистика": "Statisztika", "Язык игры": "Játék nyelve", "Выберите язык игры": "Válassza ki a játék nyelvét"}, "vi": {"Игра": "Trò chơi", "Профиль": "Hồ sơ", "Статистика": "Thống kê", "Язык игры": "Ngôn ngữ trò chơi", "Выберите язык игры": "Chọn ngôn ngữ trò chơi"}, "el": {"Игра": "Παιχνίδι", "Профиль": "Προφίλ", "Статистика": "Στατιστική", "Язык игры": "Γλώσσα παιχνιδιού", "Выберите язык игры": "Επιλέξτε τη γλώσσα του παιχνιδιού"}, "id": {"Игра": "Permainan", "Профиль": "Profil", "Статистика": "Statistik", "Язык игры": "Bahasa Permainan", "Выберите язык игры": "Pilih bahasa permainan"}, "ro": {"Игра": "Joc", "Профиль": "Profil", "Статистика": "Statistici", "Язык игры": "Limbajul jocului", "Выберите язык игры": "Alege limba jocului"}, "th": {"Игра": "เกม", "Профиль": "ประวัติโดยย่อ", "Статистика": "สถิติ", "Язык игры": "ภาษาของเกม", "Выберите язык игры": "เลือกภาษาของเกม"}, "ta": {"Игра": "விளையாட்டு", "Профиль": "சுயவிவரம்", "Статистика": "புள்ளிவிவரங்கள்", "Язык игры": "விளையாட்டு மொழி", "Выберите язык игры": "விளையாட்டு மொழியை தேர்வு செய்யவும்"}, "te": {"Игра": "గేమ్", "Профиль": "ప్రొఫైల్", "Статистика": "గణాంకాలు", "Язык игры": "గేమ్ భాష", "Выберите язык игры": "ఆట భాషను ఎంచుకోండి"}, "tr": {"Игра": "Oyun", "Профиль": "Profil", "Статистика": "İstatistikler", "Язык игры": "Oyun Dili", "Выберите язык игры": "Oyun dilini seçin"}, "fil": {"Игра": "Laro", "Профиль": "Profile", "Статистика": "Mga istatistika", "Язык игры": "Wika ng Laro", "Выберите язык игры": "Pumili ng wika ng laro"}}
"""#.utf8))
        let selected = ProcessInfo.processInfo.environment["CAPITALS_CAPTURE_LANGUAGES"]?.split(separator: ",").map(String.init) ?? labels.keys.sorted()
        let app = XCUIApplication()
        func capture(_ language: String, _ screen: String) {
            let screenshot = XCUIScreen.main.screenshot()
            let image = XCTAttachment(screenshot: screenshot)
            image.name = "store-" + language + "-" + screen
            image.lifetime = .keepAlways; add(image)
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("capitals-store-captures/" + language)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try screenshot.pngRepresentation.write(to: directory.appendingPathComponent(screen + ".png"))
            } catch { XCTFail("Cannot persist marketing screenshot: \(error)") }
        }
        for language in selected {
            let text = try XCTUnwrap(labels[language])
            let base = ["UITesting", "-onboarding.hasCompletedFullScreen.v2", "YES", "-guide.completed", "YES", "-guide.pending", "NO", "-selectedLanguage", language, "-AppleLanguages", "(\(language))", "-AppleLocale", language]
            app.launchArguments = base; app.launch()
            XCTAssertTrue(app.buttons["home.play"].firstMatch.waitForExistence(timeout: 35))
            capture(language, "home")
            app.buttons[text["Статистика"]!].firstMatch.tap()
            capture(language, "progress")
            let profile = app.buttons[text["Профиль"]!].firstMatch
            if profile.waitForExistence(timeout: 3) {
                profile.tap()
            } else {
                // Open the real Profile view when iPad's localized tab overflow hides its item.
                app.terminate()
                app.launchArguments = ["UITestingMarketingProfile"] + base
                app.launch()
            }
            let settings = app.buttons["profile.settings"]
            XCTAssertTrue(settings.waitForExistence(timeout: 10)); settings.tap()
            let picker = app.buttons.containing(.staticText, identifier: text["Язык игры"]!).firstMatch
            XCTAssertTrue(picker.waitForExistence(timeout: 10)); picker.tap()
            XCTAssertTrue(app.staticTexts[text["Выберите язык игры"]!].waitForExistence(timeout: 10))
            capture(language, "languages")
            app.terminate(); app.launchArguments = base; app.launch()
            XCTAssertTrue(app.buttons["home.play"].firstMatch.waitForExistence(timeout: 35))
            app.buttons["home.play"].firstMatch.tap()
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quiz.answer.")).firstMatch.waitForExistence(timeout: 35))
            XCTAssertTrue(app.otherElements["capital.photo"].exists)
            capture(language, "quiz")
            app.terminate(); app.launchArguments = ["LearningCaptureEurope"] + base; app.launch()
            XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 15))
            capture(language, "library"); app.terminate()
        }
    }
}
