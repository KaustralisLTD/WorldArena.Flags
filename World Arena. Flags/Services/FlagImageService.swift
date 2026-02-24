import Foundation
import SwiftUI
#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

// Простая реализация AsyncSemaphore для контроля одновременных загрузок
actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
    }
    
    func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            value += 1
        }
    }
}

@MainActor
class FlagImageService: ObservableObject {
    static let shared = FlagImageService()
    
    private let session: URLSession
    #if os(iOS)
    let cache = NSCache<NSString, UIImage>()
    #elseif os(macOS)
    let cache = NSCache<NSString, NSImage>()
    #endif
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0  // Уменьшаем таймаут для быстрого старта
        config.timeoutIntervalForResource = 10.0
        config.waitsForConnectivity = true  // Ждем подключения
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024)
        
        // Улучшенные заголовки
        config.httpAdditionalHeaders = [
            "User-Agent": "WorldArena-Flags/1.0 (iOS)",
            "Accept": "image/png,image/jpeg,image/webp,image/*",
            "Cache-Control": "public, max-age=3600"
        ]
        
        // Настройки соединения - увеличиваем для быстрой загрузки
        config.httpMaximumConnectionsPerHost = 6
        config.httpShouldUsePipelining = false
        
        session = URLSession(configuration: config)
    }
    
    func loadImage(from url: URL) async -> PlatformImage? {
        // Проверяем кэш
        let cacheKey = url.absoluteString as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Пробуем загрузить с retry логикой (3 попытки для основного URL)
        if let image = await loadImageWithRetry(from: url, attempts: 3) {
            return image
        }
        
        // Если все не удалось, возвращаем placeholder изображение
        return createPlaceholderImage(for: url)
    }

    // Самый быстрый путь: гонка между основным и альтернативными источниками, берём первый успешный ответ
    func loadImageRacing(from originalUrl: URL) async -> PlatformImage? {
        let cacheKey = originalUrl.absoluteString as NSString
        if let cached = cache.object(forKey: cacheKey) { return cached }

        // 0) Пытаемся загрузить локальный ассет из бандла мгновенно
        if let local = loadLocalFlag(for: originalUrl) {
            cache.setObject(local, forKey: cacheKey)
            return local
        }
        let primaryUrl = upscaleIfPossible(originalUrl)
        var candidates: [URL] = []
        // Ставим быстрых конкурентов первыми: флагпедиа 580, флагcdn 640/320, flagsapi
        candidates.append(contentsOf: buildAlternativeUrls(for: primaryUrl))
        candidates.insert(primaryUrl, at: 0)

        // Гонка запросов с короткими таймаутами
        return await withTaskGroup(of: PlatformImage?.self) { group in
            for url in candidates {
                group.addTask { [session] in
                    var request = URLRequest(url: url)
                    request.timeoutInterval = 1.2
                    do {
                        let (data, _) = try await session.data(for: request)
                        #if os(iOS)
                        if let image = UIImage(data: data) {
                            return image
                        }
                        #else
                        if let image = NSImage(data: data) {
                            return image
                        }
                        #endif
                    } catch { }
                    return nil
                }
            }

            var resultImage: PlatformImage?
            for await candidate in group {
                if let image = candidate {
                    resultImage = image
                    group.cancelAll()
                    break
                }
            }

            if let img = resultImage {
                self.cache.setObject(img, forKey: cacheKey)
                return img
            }

            return createPlaceholderImage(for: primaryUrl)
        }
    }
    
    private func createPlaceholderImage(for url: URL) -> PlatformImage? {
        // Извлекаем код страны из URL
        let fileName = url.lastPathComponent
        let countryCode = fileName.replacingOccurrences(of: ".png", with: "").uppercased()
        
        print("🎨 Creating placeholder for: \(countryCode)")
        
        // Создаем простое изображение с кодом страны
        #if os(iOS)
        let size = CGSize(width: 320, height: 213)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Фон
            cgContext.setFillColor(UIColor.systemBlue.withAlphaComponent(0.3).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Рамка
            cgContext.setStrokeColor(UIColor.systemBlue.cgColor)
            cgContext.setLineWidth(2.0)
            cgContext.stroke(CGRect(origin: .zero, size: size))
            
            // Текст
            let text = countryCode
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.systemBlue
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        #else
        // macOS placeholder implementation
        let size = CGSize(width: 320, height: 213)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.systemBlue.withAlphaComponent(0.3).setFill()
        NSRect(origin: .zero, size: size).fill()
        NSColor.systemBlue.setStroke()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).stroke()
        let text = NSAttributedString(string: countryCode, attributes: [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.systemBlue
        ])
        let textSize = text.size()
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect)
        image.unlockFocus()
        return image
        #endif
    }
    
    // Предзагрузка флагов для списка стран
    func preloadFlags(for countries: [Country]) async {
        print("🚀 Starting preload for \(countries.count) flags")
        
        let startTime = Date()
        var successCount = 0
        var failureCount = 0
        
        // Загружаем флаги параллельно, но ограничиваем количество одновременных запросов
        await withTaskGroup(of: (String, Bool).self) { group in
            let semaphore = AsyncSemaphore(value: 2) // Уменьшаем до 2 одновременных загрузок
            
            for country in countries {
                group.addTask {
                    await semaphore.wait()
                    defer { 
                        Task { await semaphore.signal() }
                    }
                    
                    let success = await self.preloadSingleFlag(for: country)
                    return (country.name.common, success)
                }
            }
            
            for await (countryName, success) in group {
                if success {
                    successCount += 1
                    print("✅ Preloaded flag for \(countryName)")
                } else {
                    failureCount += 1
                    print("❌ Failed to preload flag for \(countryName)")
                }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("🏁 Preload completed in \(String(format: "%.2f", duration))s")
        print("📊 Success: \(successCount), Failed: \(failureCount)")
    }
    
    private func preloadSingleFlag(for country: Country) async -> Bool {
        let flagURL = country.flagURL
        let image = await loadImageWithRetry(from: flagURL, attempts: 1) // Только одна попытка при предзагрузке
        return image != nil
    }
    
    // Предзагрузка флагов с callback для отслеживания прогресса
    func preloadFlagsWithProgress(for countries: [Country], progressCallback: @escaping (Double) -> Void) async {
        let totalCount = countries.count
        var completedCount = 0
        
        print("🚀 Starting preload for \(totalCount) flags")
        let startTime = Date()
        
        // Загружаем флаги параллельно с ограничением - увеличиваем для быстрой загрузки
        await withTaskGroup(of: (String, Bool).self) { group in
            let semaphore = AsyncSemaphore(value: 6) // Увеличиваем до 6 одновременных загрузок
            
            for country in countries {
                group.addTask {
                    await semaphore.wait()
                    defer { 
                        Task { await semaphore.signal() }
                        completedCount += 1
                        let progress = Double(completedCount) / Double(totalCount)
                        progressCallback(progress)
                    }
                    
                    let flagURL = country.flagURL
                    
                    let image = await self.loadImageWithRetry(from: flagURL, attempts: 1)
                    let success = image != nil
                    
                    if success {
                        print("✅ Preloaded flag for \(country.name.common)")
                    } else {
                        print("❌ Failed to preload flag for \(country.name.common)")
                    }
                    
                    return (country.name.common, success)
                }
            }
            
            var successCount = 0
            var failureCount = 0
            
            for await (_, success) in group {
                if success {
                    successCount += 1
                } else {
                    failureCount += 1
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            print("🏁 Preload completed in \(String(format: "%.2f", duration))s")
            print("📊 Success: \(successCount), Failed: \(failureCount)")
        }
    }

    // Оппортунистическая предзагрузка: ограничиваемся окном и бюджетом времени
    func preloadFlagsOpportunistic(
        for countries: [Country],
        startIndex: Int,
        count: Int,
        maxDuration: TimeInterval,
        progressCallback: ((Double) -> Void)? = nil
    ) async {
        guard !countries.isEmpty else { return }
        let safeStart = max(0, min(startIndex, countries.count - 1))
        let end = min(safeStart + max(0, count), countries.count)
        guard end > safeStart else { return }

        let slice = Array(countries[safeStart..<end])
        let total = slice.count
        if total == 0 { return }

        let startedAt = Date()
        var completed = 0
        var successCount = 0
        var failureCount = 0

        print("🚀 Opportunistic preload window [\(safeStart)..<\(end)] (\(total) flags), time budget: \(String(format: "%.1f", maxDuration))s")

        await withTaskGroup(of: Bool.self) { group in
            // Небольшая конкуретность, чтобы не мешать основному потоку UI/игры
            let semaphore = AsyncSemaphore(value: 4)
            for country in slice {
                // Проверяем кэш заранее
                let key = country.flagURL.absoluteString as NSString
                if cache.object(forKey: key) != nil {
                    completed += 1
                    progressCallback?(Double(completed) / Double(total))
                    continue
                }

                group.addTask { [weak self] in
                    guard let self else { return false }
                    await semaphore.wait()
                    defer { Task { await semaphore.signal() } }

                    // Проверка бюджета времени/отмены перед началом
                    if Task.isCancelled { return false }
                    if Date().timeIntervalSince(startedAt) > maxDuration { return false }

                    // Быстрый загрузчик с гонкой источников
                    let ok = await self.loadImageRacing(from: country.flagURL) != nil
                    return ok
                }
            }

            for await ok in group {
                if Task.isCancelled { break }
                completed += 1
                if ok { successCount += 1 } else { failureCount += 1 }
                progressCallback?(Double(completed) / Double(total))

                // Прерываем, если вышли за бюджет времени
                if Date().timeIntervalSince(startedAt) > maxDuration {
                    print("⏹️ Opportunistic preload stopped by time budget (\(String(format: "%.1f", Date().timeIntervalSince(startedAt)))s)")
                    group.cancelAll()
                    break
                }
            }
        }

        let spent = Date().timeIntervalSince(startedAt)
        print("🏁 Opportunistic preload finished in \(String(format: "%.2f", spent))s — success: \(successCount), failed: \(failureCount), completed: \(completed)/\(total)")
    }
    
    // Быстрая загрузка одного изображения с коротким таймаутом — для первого флага
    func loadImageFast(from url: URL) async -> PlatformImage? {
        let cacheKey = url.absoluteString as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        let primaryUrl = upscaleIfPossible(url)
        do {
            var request = URLRequest(url: primaryUrl)
            request.timeoutInterval = 2.5
            let (data, _) = try await session.data(for: request)
            #if os(iOS)
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: cacheKey)
                return image
            }
            #else
            if let image = NSImage(data: data) {
                cache.setObject(image, forKey: cacheKey)
                return image
            }
            #endif
        } catch {
            // fallthrough to alternatives
        }
        // Попробуем альтернативные источники кратким таймаутом
        let pathComponents = primaryUrl.pathComponents
        guard let fileName = pathComponents.last else { return createPlaceholderImage(for: primaryUrl) }
        let countryCode = fileName.replacingOccurrences(of: ".png", with: "").uppercased()
        let mappedCode = mapCountryCodeForAlternativeAPIs(countryCode)
        var alt: [URL] = []
        if countryCode == "XK" {
            alt = [
                URL(string: "https://flagpedia.net/data/flags/w580/xk.png"),
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Flag_of_Kosovo.svg/320px-Flag_of_Kosovo.svg.png"),
                URL(string: "https://www.worldometers.info/img/flags/kv-flag.gif"),
                URL(string: "https://flagsapi.com/XK/flat/64.png")
            ].compactMap { $0 }
        } else {
            alt = [
                URL(string: "https://flagcdn.com/w640/\(mappedCode.lowercased()).png"),
                URL(string: "https://flagcdn.com/w320/\(mappedCode.lowercased()).png"),
                URL(string: "https://flagpedia.net/data/flags/w580/\(mappedCode.lowercased()).png"),
                URL(string: "https://flagsapi.com/\(mappedCode)/flat/64.png")
            ].compactMap { $0 }
        }
        for u in alt {
            do {
                var r = URLRequest(url: u)
                r.timeoutInterval = 2.5
                let (data, _) = try await session.data(for: r)
                #if os(iOS)
                if let image = UIImage(data: data) {
                    cache.setObject(image, forKey: cacheKey)
                    return image
                }
                #else
                if let image = NSImage(data: data) {
                    cache.setObject(image, forKey: cacheKey)
                    return image
                }
                #endif
            } catch { continue }
        }
        return createPlaceholderImage(for: primaryUrl)
    }

    private func upscaleIfPossible(_ url: URL) -> URL {
        var urlString = url.absoluteString
        // Повышаем качество для flagcdn
        urlString = urlString.replacingOccurrences(of: "/w320/", with: "/w640/")
        urlString = urlString.replacingOccurrences(of: "/w256/", with: "/w640/")
        urlString = urlString.replacingOccurrences(of: "/w128/", with: "/w640/")
        return URL(string: urlString) ?? url
    }

    func loadImageWithRetry(from url: URL, attempts: Int) async -> PlatformImage? {
        let primaryUrl = upscaleIfPossible(url)
        print("🏁 Loading flag from: \(primaryUrl)")
        
        for attempt in 1...attempts {
            do {
                print("📡 Attempt \(attempt) for: \(primaryUrl.lastPathComponent)")
                let (data, response) = try await session.data(from: primaryUrl)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode) for \(primaryUrl.lastPathComponent)")
                }
                
                #if os(iOS)
                guard let image = UIImage(data: data) else {
                    print("❌ Failed to create image from data for: \(primaryUrl.lastPathComponent)")
                    continue
                }
                #else
                guard let image = NSImage(data: data) else {
                    print("❌ Failed to create image from data for: \(primaryUrl.lastPathComponent)")
                    continue
                }
                #endif
                
                print("✅ Successfully loaded flag: \(url.lastPathComponent)")
                
                // Сохраняем в кэш
                let cacheKey = primaryUrl.absoluteString as NSString
                cache.setObject(image, forKey: cacheKey)
                return image
            } catch {
                print("❌ Attempt \(attempt) failed for \(primaryUrl.lastPathComponent): \(error)")
                
                if attempt < attempts {
                    // Экспоненциальная задержка перед повторной попыткой
                    let delay = Double(attempt) * 0.5  // 0.5, 1.0, 1.5 секунды
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        print("🔄 Trying alternative sources for: \(primaryUrl.lastPathComponent)")
        print("⚠️ Primary source failed after \(attempts) attempts")
        // Если все попытки неудачны, пробуем альтернативные источники
        return await tryAlternativeSources(for: primaryUrl)
    }
    
    private func tryAlternativeSources(for originalUrl: URL) async -> PlatformImage? {
        let alternativeUrls = buildAlternativeUrls(for: originalUrl)
        for (index, altUrl) in alternativeUrls.enumerated() {
            do {
                print("🔄 Alternative source \(index + 1): \(altUrl)")
                var req = URLRequest(url: altUrl)
                req.timeoutInterval = 1.2
                let (data, response) = try await session.data(for: req)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 Alt HTTP Status: \(httpResponse.statusCode)")
                }
                
                #if os(iOS)
                if let image = UIImage(data: data) {
                    print("✅ Successfully loaded flag from alternative source: \(altUrl)")
                    // Сохраняем в кэш под оригинальным URL
                    let cacheKey = originalUrl.absoluteString as NSString
                    cache.setObject(image, forKey: cacheKey)
                    return image
                }
                #else
                if let image = NSImage(data: data) {
                    print("✅ Successfully loaded flag from alternative source: \(altUrl)")
                    // Сохраняем в кэш под оригинальным URL
                    let cacheKey = originalUrl.absoluteString as NSString
                    cache.setObject(image, forKey: cacheKey)
                    return image
                }
                #endif
            } catch {
                print("❌ Alternative source \(index + 1) failed: \(error)")
            }
        }
        
        print("💥 All flag sources failed for: \(originalUrl.lastPathComponent)")
        return nil
    }
    
    // Маппинг проблематичных кодов стран для альтернативных API
    private func mapCountryCodeForAlternativeAPIs(_ code: String) -> String {
        let mapping: [String: String] = [
            "XK": "XK",  // Kosovo - некоторые API поддерживают XK
            "TW": "TW",  // Taiwan
            "PS": "PS",  // Palestine
            "EH": "EH"   // Western Sahara
        ]
        return mapping[code] ?? code
    }

    private func buildCandidateUrls(for original: URL) -> [URL] {
        var urls: [URL] = [original]
        urls.append(contentsOf: buildAlternativeUrls(for: original))
        return urls
    }

    private func buildAlternativeUrls(for originalUrl: URL) -> [URL] {
        let pathComponents = originalUrl.pathComponents
        guard let fileName = pathComponents.last else { return [] }
        let countryCode = fileName.replacingOccurrences(of: ".png", with: "").uppercased()
        let mappedCode = mapCountryCodeForAlternativeAPIs(countryCode)

        if countryCode == "XK" {
            return [
                URL(string: "https://flagpedia.net/data/flags/w580/xk.png"),
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Flag_of_Kosovo.svg/320px-Flag_of_Kosovo.svg.png"),
                URL(string: "https://www.worldometers.info/img/flags/kv-flag.gif"),
                URL(string: "https://flagsapi.com/XK/flat/64.png")
            ].compactMap { $0 }
        }

        return [
            URL(string: "https://flagpedia.net/data/flags/w580/\(mappedCode.lowercased()).png"),
            URL(string: "https://flagcdn.com/w640/\(mappedCode.lowercased()).png"),
            URL(string: "https://flagcdn.com/w320/\(mappedCode.lowercased()).png"),
            URL(string: "https://flagsapi.com/\(mappedCode)/flat/64.png")
        ].compactMap { $0 }
    }
    
    // MARK: - Local bundle fallback
    private func loadLocalFlag(for url: URL) -> PlatformImage? {
        // ожидаем имена вида xx.png в каталоге Assets.xcassets/Flags или в Resources/Flags
        let fileName = url.lastPathComponent.lowercased() // e.g., it.png
        let code = fileName.replacingOccurrences(of: ".png", with: "")
        // 1) Пытаемся найти по корню бандла: <code>.png (Xcode копирует в корень по умолчанию)
        if let bundleUrl = Bundle.main.url(forResource: code, withExtension: "png") {
            #if os(iOS)
            if let data = try? Data(contentsOf: bundleUrl), let img = UIImage(data: data) {
                return img
            }
            #else
            if let data = try? Data(contentsOf: bundleUrl), let img = NSImage(data: data) {
                return img
            }
            #endif
        }
        // 2) Пытаемся найти в подпапке "Flags/<code>.png" (если сохранено структурой папок)
        if let bundleUrl = Bundle.main.url(forResource: code, withExtension: "png", subdirectory: "Flags") {
            #if os(iOS)
            if let data = try? Data(contentsOf: bundleUrl), let img = UIImage(data: data) {
                return img
            }
            #else
            if let data = try? Data(contentsOf: bundleUrl), let img = NSImage(data: data) {
                return img
            }
            #endif
        }
        // 3) Пытаемся достать из ассетов как "flag_<code>"
        #if os(iOS)
        if let imageFromAssets = UIImage(named: "flag_\(code)") {
            return imageFromAssets
        }
        #else
        if let imageFromAssets = NSImage(named: "flag_\(code)") {
            return imageFromAssets
        }
        #endif
        return nil
    }
    

}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: PlatformImage?
    @State private var isLoading = false
    @State private var loadingTask: Task<Void, Never>?
    
    var body: some View {
        Group {
            if let image = image {
                #if os(iOS)
                content(Image(uiImage: image))
                #else
                content(Image(nsImage: image))
                #endif
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
                    .onDisappear {
                        // Отменяем загрузку если view исчезает
                        loadingTask?.cancel()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        isLoading = true
        
        // Сначала проверяем кэш синхронно
        let cacheKey = url.absoluteString as NSString
        if let cachedImage = FlagImageService.shared.cache.object(forKey: cacheKey) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        loadingTask = Task.detached(priority: .userInitiated) {
            // Используем racing-загрузку для минимальной задержки
            let loadedImage = await FlagImageService.shared.loadImageRacing(from: url)
            
            await MainActor.run {
                guard !Task.isCancelled else { return }
                
                if let loadedImage = loadedImage {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.image = loadedImage
                    }
                } else {
                    print("🚫 Failed to load image for: \(url.lastPathComponent)")
                }
                self.isLoading = false
                self.loadingTask = nil
            }
        }
    }
} 