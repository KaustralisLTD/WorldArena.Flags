import Foundation
import SwiftUI

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
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3.0  // Очень короткий таймаут для быстрого переключения
        config.timeoutIntervalForResource = 10.0
        config.waitsForConnectivity = false  // Не ждем подключения
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
        
        // Добавляем User-Agent
        config.httpAdditionalHeaders = [
            "User-Agent": "WorldArena-Flags/1.0 (iOS)",
            "Accept": "image/*"
        ]
        
        session = URLSession(configuration: config)
    }
    
    func loadImage(from url: URL) async -> UIImage? {
        // Проверяем кэш
        let cacheKey = url.absoluteString as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Пробуем загрузить с retry логикой (3 попытки для основного URL)
        return await loadImageWithRetry(from: url, attempts: 3)
    }
    
    // Предзагрузка флагов для списка стран
    func preloadFlags(for countries: [Country]) async {
        print("🚀 Starting preload for \(countries.count) flags")
        
        let startTime = Date()
        var successCount = 0
        var failureCount = 0
        
        // Загружаем флаги параллельно, но ограничиваем количество одновременных запросов
        await withTaskGroup(of: (String, Bool).self) { group in
            let semaphore = AsyncSemaphore(value: 5) // Максимум 5 одновременных загрузок
            
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
        
        // Загружаем флаги параллельно с ограничением
        await withTaskGroup(of: (String, Bool).self) { group in
            let semaphore = AsyncSemaphore(value: 3) // Ограничиваем до 3 одновременных загрузок
            
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
    
    private func loadImageWithRetry(from url: URL, attempts: Int) async -> UIImage? {
        print("🏁 Loading flag from: \(url)")
        
        for attempt in 1...attempts {
            do {
                print("📡 Attempt \(attempt) for: \(url.lastPathComponent)")
                let (data, response) = try await session.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status: \(httpResponse.statusCode) for \(url.lastPathComponent)")
                }
                
                guard let image = UIImage(data: data) else {
                    print("❌ Failed to create image from data for: \(url.lastPathComponent)")
                    continue
                }
                
                print("✅ Successfully loaded flag: \(url.lastPathComponent)")
                
                // Сохраняем в кэш
                let cacheKey = url.absoluteString as NSString
                cache.setObject(image, forKey: cacheKey)
                return image
            } catch {
                print("❌ Attempt \(attempt) failed for \(url.lastPathComponent): \(error)")
                
                if attempt < attempts {
                    // Минимальная задержка перед повторной попыткой
                    let delay = 0.2
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        print("🔄 Trying alternative sources for: \(url.lastPathComponent)")
        print("⚠️ Primary source failed after \(attempts) attempts")
        // Если все попытки неудачны, пробуем альтернативные источники
        return await tryAlternativeSources(for: url)
    }
    
    private func tryAlternativeSources(for originalUrl: URL) async -> UIImage? {
        // Извлекаем код страны из URL
        let pathComponents = originalUrl.pathComponents
        guard let fileName = pathComponents.last else { 
            print("❌ Cannot extract filename from: \(originalUrl)")
            return nil 
        }
        
        let countryCode = fileName.replacingOccurrences(of: ".png", with: "").uppercased()
        print("🔍 Country code: \(countryCode)")
        
        // Специальная обработка для проблематичных стран
        let mappedCode = mapCountryCodeForAlternativeAPIs(countryCode)
        print("🗺️ Mapped code: \(mappedCode)")
        
        var alternativeUrls: [URL] = []
        
        // Специальные URL для Kosovo
        if countryCode == "XK" {
            alternativeUrls = [
                URL(string: "https://flagpedia.net/data/flags/w580/xk.png"),
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Flag_of_Kosovo.svg/320px-Flag_of_Kosovo.svg.png"),
                URL(string: "https://www.worldometers.info/img/flags/kv-flag.gif"),
                URL(string: "https://flagsapi.com/XK/flat/64.png")
            ].compactMap { $0 }
        } else {
            // Используем только надежные источники
            alternativeUrls = [
                URL(string: "https://flagsapi.com/\(mappedCode)/flat/64.png"),
                URL(string: "https://flagpedia.net/data/flags/w580/\(mappedCode.lowercased()).png"),
                URL(string: "https://www.countryflags.io/\(mappedCode)/flat/64.png")
            ].compactMap { $0 }
        }
        
        for (index, altUrl) in alternativeUrls.enumerated() {
            do {
                print("🔄 Alternative source \(index + 1): \(altUrl)")
                let (data, response) = try await session.data(from: altUrl)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 Alt HTTP Status: \(httpResponse.statusCode)")
                }
                
                if let image = UIImage(data: data) {
                    print("✅ Successfully loaded flag from alternative source: \(altUrl)")
                    // Сохраняем в кэш под оригинальным URL
                    let cacheKey = originalUrl.absoluteString as NSString
                    cache.setObject(image, forKey: cacheKey)
                    return image
                }
            } catch {
                print("❌ Alternative source \(index + 1) failed: \(error)")
            }
        }
        
        print("💥 All flag sources failed for: \(countryCode)")
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
    

}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        isLoading = true
        
        Task.detached(priority: .userInitiated) {
            let loadedImage = await FlagImageService.shared.loadImage(from: url)
            
            await MainActor.run {
                if let loadedImage = loadedImage {
                    self.image = loadedImage
                } else {
                    print("🚫 Failed to load image for: \(url.lastPathComponent)")
                }
                self.isLoading = false
            }
        }
    }
} 