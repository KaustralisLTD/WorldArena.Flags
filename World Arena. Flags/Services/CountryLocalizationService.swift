import Foundation

/// Сервис для загрузки локализованных данных о странах (описания флагов, гимнов, факты)
/// Поддерживает загрузку из API или бэкенда
class CountryLocalizationService {
    static let shared = CountryLocalizationService()
    
    // Базовый URL для бэкенда (можно настроить через конфигурацию)
    private let baseURL = "https://api.flags.world" // TODO: Заменить на реальный URL бэкенда
    
    private let session: URLSession
    
    private init() {
        // Настраиваем URLSession с правильной конфигурацией для TLS
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.waitsForConnectivity = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        // Настройки для HTTPS/TLS
        config.httpAdditionalHeaders = [
            "User-Agent": "WorldArena-Flags/1.0 (iOS)",
            "Accept": "application/json",
            "Accept-Language": "en,ru,uk"
        ]
        
        session = URLSession(configuration: config)
    }
    
    // MARK: - API Models
    
    struct LocalizedCountryContent: Codable {
        let code: String
        let language: String
        let flagDescription: String?
        let anthemDescription: String?
        let anthemMeaning: String?
        let anthemText: String?
        let anthemAudioURL: String?
        let interestingFacts: [String]?
    }
    
    struct LocalizedCountryContentResponse: Codable {
        let success: Bool
        let data: LocalizedCountryContent?
        let error: String?
    }
    
    // MARK: - Fetch Methods
    
    /// Загружает локализованный контент для страны из API/бэкенда
    @MainActor
    func fetchLocalizedContent(for countryCode: String, language: String) async throws -> LocalizedCountryContent? {
        // TODO: Реализовать реальный запрос к API/бэкенду
        // Пример URL: https://api.flags.world/v1/countries/{code}/content?lang={language}
        
        let urlString = "\(baseURL)/v1/countries/\(countryCode.lowercased())/content?lang=\(language)"
        guard let url = URL(string: urlString) else {
            print("⚠️ Invalid URL for country content: \(urlString)")
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.cachePolicy = .returnCacheDataElseLoad
            
            let (data, response) = try await session.data(for: request)
            
            // Проверяем HTTP статус
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("⚠️ API returned HTTP \(httpResponse.statusCode) for \(countryCode)")
                    return nil
                }
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let apiResponse = try decoder.decode(LocalizedCountryContentResponse.self, from: data)
            
            if apiResponse.success, let content = apiResponse.data {
                print("✅ Successfully loaded localized content for \(countryCode) (\(language))")
                return content
            } else {
                print("⚠️ API returned error for \(countryCode): \(apiResponse.error ?? "Unknown error")")
                return nil
            }
        } catch let error as URLError {
            // Детальная обработка ошибок URL
            switch error.code {
            case .notConnectedToInternet:
                print("⚠️ No internet connection for \(countryCode)")
            case .timedOut:
                print("⚠️ Request timeout for \(countryCode)")
            case .cannotConnectToHost:
                print("⚠️ Cannot connect to host for \(countryCode)")
            case .secureConnectionFailed:
                print("⚠️ TLS/SSL error for \(countryCode): \(error.localizedDescription)")
                print("   Error code: \(error.code.rawValue)")
                print("   This may be due to server SSL/TLS configuration issues.")
                print("   Falling back to local content.")
            case .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot:
                print("⚠️ SSL certificate error for \(countryCode): \(error.localizedDescription)")
            default:
                print("⚠️ Network error for \(countryCode): \(error.localizedDescription) (code: \(error.code.rawValue))")
            }
            // Возвращаем nil при ошибке - будет использован fallback из CountryDetailsService
            return nil
        } catch {
            print("⚠️ Failed to fetch localized content for \(countryCode): \(error.localizedDescription)")
            print("   Error type: \(type(of: error))")
            // Возвращаем nil при ошибке - будет использован fallback из CountryDetailsService
            return nil
        }
    }
    
    /// Загружает локализованный контент для нескольких стран одновременно
    @MainActor
    func fetchLocalizedContentBatch(for countryCodes: [String], language: String) async -> [String: LocalizedCountryContent] {
        var results: [String: LocalizedCountryContent] = [:]
        
        await withTaskGroup(of: (String, LocalizedCountryContent?).self) { group in
            for code in countryCodes {
                group.addTask {
                    do {
                        let content = try await self.fetchLocalizedContent(for: code, language: language)
                        return (code, content)
                    } catch {
                        return (code, nil)
                    }
                }
            }
            
            for await (code, content) in group {
                if let content = content {
                    results[code] = content
                }
            }
        }
        
        return results
    }
    
    // MARK: - Fallback Methods (используются если API недоступен)
    
    /// Получить описание флага из локальной базы (fallback)
    /// Используется существующая логика из CountryDetailsService через приватные методы
    func getFlagDescriptionFallback(for code: String, language: String) -> String {
        // Fallback будет обрабатываться в CountryDetailsService
        return "The national flag represents the country's identity, history, and values."
    }
    
    /// Получить описание гимна из локальной базы (fallback)
    func getAnthemDescriptionFallback(for code: String, language: String) -> String {
        return "The national anthem is a symbol of national pride and unity, representing the country's history and aspirations."
    }
    
    /// Получить значение гимна из локальной базы (fallback)
    func getAnthemMeaningFallback(for code: String, language: String) -> String {
        return "The anthem celebrates the country's natural beauty, cultural heritage, and the unity of its people."
    }
    
    /// Получить интересные факты из локальной базы (fallback)
    func getInterestingFactsFallback(for code: String, language: String) -> [String] {
        return [
            "This country has a rich cultural heritage.",
            "The country is known for its unique traditions.",
            "There are many interesting facts about this nation."
        ]
    }
}
