import Foundation
#if os(iOS)
import AVFoundation
#endif
import SwiftUI

@MainActor
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var isPlaying = false
    @Published var currentProgress: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var currentTime: Double = 0.0
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    
    #if os(iOS)
    private var audioPlayer: AVAudioPlayer?
    #endif
    private var progressTimer: Timer?
    private var currentAudioFile: String?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Ошибка настройки аудиосессии: \(error)")
        }
        #endif
    }
    
    func playAnthem(for countryCode: String) {
        // Останавливаем текущее воспроизведение
        stopAudio()
        
        // Формируем URL для загрузки с сервера
        let audioFileName = "anthem_\(countryCode.lowercased()).m4a"
        let serverURL = "https://flags.worldarena.games/anthems/\(audioFileName)"
        
        print("🎵 Запрос на воспроизведение гимна для страны: \(countryCode)")
        
        // Проверяем, есть ли файл в кэше
        if let cachedURL = getCachedAudioURL(for: countryCode) {
            print("📁 Найден кэшированный файл: \(cachedURL.lastPathComponent)")
            playAudioFromURL(cachedURL)
            return
        }
        
        // Проверяем доступность сервера
        checkServerAvailability { [weak self] isAvailable in
            if isAvailable {
                print("🌐 Сервер доступен, загружаем гимн")
                self?.downloadAndPlayAnthem(from: serverURL, countryCode: countryCode)
            } else {
                print("❌ Сервер недоступен, включаем симуляцию")
                self?.playSimulatedAudio()
            }
        }
    }
    
    func pauseAudio() {
        #if os(iOS)
        audioPlayer?.pause()
        #endif
        isPlaying = false
        stopProgressTimer()
    }
    
    func resumeAudio() {
        #if os(iOS)
        audioPlayer?.play()
        #endif
        isPlaying = true
        startProgressTimer()
    }
    
    func stopAudio() {
        #if os(iOS)
        audioPlayer?.stop()
        audioPlayer = nil
        #endif
        isPlaying = false
        currentProgress = 0.0
        currentTime = 0.0
        duration = 0.0
        currentAudioFile = nil
        stopProgressTimer()
    }
    
    func seekTo(_ progress: Double) {
        #if os(iOS)
        guard let player = audioPlayer, duration > 0 else { return }
        
        let targetTime = duration * progress
        player.currentTime = targetTime
        currentTime = targetTime
        currentProgress = progress
        #endif
    }
    
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                #if os(iOS)
                guard let self = self, let player = self.audioPlayer else { return }
                
                self.currentTime = player.currentTime
                self.currentProgress = player.currentTime / player.duration
                
                // Если воспроизведение закончилось
                if !player.isPlaying && self.isPlaying {
                    self.stopAudio()
                }
                #endif
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func playSimulatedAudio() {
        print("🎵 Симуляция воспроизведения гимна")
        isPlaying = true
        duration = 90.0 // 1:30 минуты
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.currentProgress < 1.0 {
                    self.currentProgress += 0.001 // Медленное увеличение
                    self.currentTime = self.duration * self.currentProgress
                } else {
                    self.stopAudio()
                }
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    // Проверка наличия аудиофайла
    func hasAudioFile(for countryCode: String) -> Bool {
        let audioFileName = "anthem_\(countryCode.lowercased())"
        return Bundle.main.url(forResource: audioFileName, withExtension: "mp3") != nil
    }
    
    // Получение списка всех доступных аудиофайлов
    func getAvailableAudioFiles() -> [String] {
        let bundle = Bundle.main
        var availableFiles: [String] = []
        
        // Проверяем разные форматы
        let extensions = ["mp3", "wav", "m4a"]
        
        for ext in extensions {
            let urls = bundle.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            
            for url in urls {
                let filename = url.lastPathComponent
                if filename.hasPrefix("anthem_") {
                    let countryCode = String(filename.dropFirst(7).dropLast(ext.count + 1)) // Убираем "anthem_" и расширение
                    if !availableFiles.contains(countryCode) {
                        availableFiles.append(countryCode)
                    }
                }
            }
        }
        
        return availableFiles.sorted()
    }
    
    // MARK: - Server Audio Methods
    
    private func getCachedAudioURL(for countryCode: String) -> URL? {
        let fileName = "anthem_\(countryCode.lowercased()).m4a"
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        let fileURL = cacheDirectory?.appendingPathComponent(fileName)
        
        // Проверяем существование и размер файла
        if let url = fileURL, FileManager.default.fileExists(atPath: url.path) {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes?[.size] as? Int64 ?? 0
            
            // Файл должен быть больше 10KB
            if fileSize > 10240 {
                return url
            } else {
                print("⚠️ Кэшированный файл слишком маленький, удаляем")
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        return nil
    }
    
    private func checkServerAvailability(completion: @escaping (Bool) -> Void) {
        let testURL = "https://flags.worldarena.games/anthems/test.m4a"
        
        guard let url = URL(string: testURL) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    // Сервер доступен, даже если файл не найден (404)
                    completion(httpResponse.statusCode < 500)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    func clearCache() {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            let anthemFiles = files.filter { $0.lastPathComponent.hasPrefix("anthem_") && $0.lastPathComponent.hasSuffix(".m4a") }
            
            for file in anthemFiles {
                try FileManager.default.removeItem(at: file)
                print("🗑️ Удален кэшированный файл: \(file.lastPathComponent)")
            }
            
            print("✅ Кэш очищен, удалено \(anthemFiles.count) файлов")
        } catch {
            print("❌ Ошибка очистки кэша: \(error)")
        }
    }
    
    func getCacheSize() -> Int64 {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return 0
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            let anthemFiles = files.filter { $0.lastPathComponent.hasPrefix("anthem_") && $0.lastPathComponent.hasSuffix(".m4a") }
            
            var totalSize: Int64 = 0
            for file in anthemFiles {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                totalSize += attributes[.size] as? Int64 ?? 0
            }
            
            return totalSize
        } catch {
            return 0
        }
    }
    
    private func playAudioFromURL(_ url: URL) {
        #if os(iOS)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0.0
            currentAudioFile = url.lastPathComponent
            
            audioPlayer?.play()
            isPlaying = true
            
            startProgressTimer()
            
            print("🎵 Воспроизводится гимн из кэша: \(url.lastPathComponent)")
            
        } catch {
            print("❌ Ошибка воспроизведения аудио из кэша: \(error)")
            playSimulatedAudio()
        }
        #else
        // macOS implementation would go here
        playSimulatedAudio()
        #endif
    }
    
    private func downloadAndPlayAnthem(from serverURL: String, countryCode: String) {
        guard let url = URL(string: serverURL) else {
            print("❌ Неверный URL сервера: \(serverURL)")
            playSimulatedAudio()
            return
        }
        
        print("📥 Загружаем гимн с сервера: \(serverURL)")
        
        // Показываем индикатор загрузки
        isDownloading = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.isDownloading = false
                
                if let error = error {
                    print("❌ Ошибка загрузки: \(error)")
                    self.playSimulatedAudio()
                    return
                }
                
                // Проверяем HTTP статус
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        print("❌ HTTP ошибка: \(httpResponse.statusCode)")
                        self.playSimulatedAudio()
                        return
                    }
                }
                
                guard let data = data, !data.isEmpty else {
                    print("❌ Пустые данные от сервера")
                    self.playSimulatedAudio()
                    return
                }
                
                // Проверяем размер файла (минимум 10KB)
                if data.count < 10240 {
                    print("❌ Файл слишком маленький: \(data.count) байт")
                    self.playSimulatedAudio()
                    return
                }
                
                print("✅ Получено \(data.count) байт данных")
                
                // Сохраняем в кэш
                if let cachedURL = self.saveAudioToCache(data: data, countryCode: countryCode) {
                    self.playAudioFromURL(cachedURL)
                } else {
                    print("❌ Ошибка сохранения в кэш")
                    self.playSimulatedAudio()
                }
            }
        }.resume()
    }
    
    private func saveAudioToCache(data: Data, countryCode: String) -> URL? {
        let fileName = "anthem_\(countryCode.lowercased()).m4a"
        
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("💾 Гимн сохранен в кэш: \(fileName) (\(data.count) байт)")
            
            // Проверяем целостность файла
            #if os(iOS)
            if let player = try? AVAudioPlayer(contentsOf: fileURL) {
                print("✅ Файл проверен, длительность: \(player.duration) сек")
                return fileURL
            } else {
                print("❌ Файл поврежден, удаляем")
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
            #else
            // macOS: просто возвращаем URL без проверки через AVAudioPlayer
            return fileURL
            #endif
        } catch {
            print("❌ Ошибка сохранения в кэш: \(error)")
            return nil
        }
    }
}

// MARK: - AVAudioPlayerDelegate
#if os(iOS)
extension AudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stopAudio()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Ошибка декодирования аудио: \(error?.localizedDescription ?? "Неизвестная ошибка")")
        Task { @MainActor in
            self.stopAudio()
        }
    }
}
#endif