import SwiftUI

struct CountryDetailView: View {
    @State var countryCode: String
    @State var countryName: String
    @State var flagEmoji: String
    
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var countryDetail: CountryDetail?
    @State private var isLoadingDetail = false
    @State private var currentPhotoIndex = 0
    @State private var showingPhotoGallery = false
    @StateObject private var audioManager = AudioManager.shared
    @State private var allCountries: [Country] = []
    @State private var currentCountryIndex: Int = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            // Базовый фон
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Стилизованная шапка (название из деталей — локализовано)
                StylizedCountryHeader(
                    countryCode: countryCode,
                    countryName: countryDetail?.name ?? countryName,
                    flagEmoji: flagEmoji,
                    onBack: {
                        dismiss()
                    },
                    onPrevious: {
                        navigateToPreviousCountry()
                    },
                    onNext: {
                        navigateToNextCountry()
                    }
                )
                
                // Информационные бейджи
                HStack(spacing: 16) {
                    infoBadge(icon: "🏛️", title: localizationManager.localizedString("Столица"), text: countryDetail?.capital ?? "")
                    infoBadge(icon: "👥", title: localizationManager.localizedString("Население"), text: countryDetail?.population ?? "")
                    infoBadge(icon: "📏", title: localizationManager.localizedString("Площадь"), text: countryDetail?.area ?? "")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Скроллируемый контент
                ScrollView {
                    VStack(spacing: 20) {
                        // Галерея фотографий
                        photoGallerySection
                        
                        // Основная информация о стране
                        countryInfoSection
                        
                        // Интересные факты
                        interestingFactsSection
                        
                        // Описание флага
                        flagDescriptionSection
                        
                        // Аудио гимна
                        anthemSection
                    }
                    .padding(.top, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(Color(UIColor.systemGroupedBackground))
                        .ignoresSafeArea(.container, edges: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                .padding(.top, -10)
            }
        }
        .sheet(isPresented: $showingPhotoGallery) {
            PhotoGalleryModal(
                photos: CountryPhotosService.shared.getPhotos(for: countryCode).map(\.imageURL),
                currentIndex: $currentPhotoIndex,
                isPresented: $showingPhotoGallery
            )
        }
        .overlay {
            if isLoadingDetail {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().scaleEffect(1.5).tint(.white)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadCountryDetail()
            loadAllCountries()
        }
        .onDisappear {
            audioManager.stopAudio()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) > abs(vertical) else { return }
                    // Свайп вправо — возврат назад (с любой части экрана)
                    if horizontal > 80 {
                        if value.startLocation.x < 80 {
                            dismiss()
                        } else {
                            navigateToPreviousCountry()
                        }
                    }
                    // Свайп влево — следующая страна
                    else if horizontal < -80 {
                        navigateToNextCountry()
                    }
                }
        )
    }
    
    private func infoBadge(icon: String, title: String, text: String) -> some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    

    
    // MARK: - Photo Gallery Section
    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localizedString("Галерея"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    let photos = CountryPhotosService.shared.getPhotos(for: countryCode)
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                        photoCard(photo: photo, index: index)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func photoCard(photo: CountryPhoto, index: Int) -> some View {
        Button(action: {
            currentPhotoIndex = index
            showingPhotoGallery = true
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Показываем emoji как fallback для реальных фотографий
                    Text(photo.localImage)
                        .font(.system(size: 32))
                    
                    // Индикатор типа фотографии
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: photo.type.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(6)
                }
                
                // Название фотографии
                Text(photo.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 120)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Country Info Section
    private var countryInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString("Информация о стране"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                infoRow(title: localizationManager.localizedString("Столица"), value: countryDetail?.capital ?? "")
                infoRow(title: localizationManager.localizedString("Официальный язык"), value: countryDetail?.officialLanguage ?? "")
                infoRow(title: localizationManager.localizedString("Правительство"), value: countryDetail?.government ?? "")
                infoRow(title: localizationManager.localizedString("Глава государства"), value: countryDetail?.leader ?? "")
                infoRow(title: localizationManager.localizedString("Телефонный код"), value: countryDetail?.dialingCode ?? "")
                infoRow(title: localizationManager.localizedString("Население"), value: countryDetail?.population ?? "")
                infoRow(title: localizationManager.localizedString("Валюта"), value: countryDetail?.currency ?? "")
                infoRow(title: localizationManager.localizedString("Независимость"), value: countryDetail?.independence ?? "")
                infoRow(title: localizationManager.localizedString("Площадь"), value: countryDetail?.area ?? "")
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localizedString("Описание"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(countryDetail?.description ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Interesting Facts Section
    private var interestingFactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString("Интересные факты"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                if let facts = countryDetail?.interestingFacts {
                    ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                        factCard(
                            icon: getFactIcon(for: index),
                            title: localizationManager.localizedString("Факт") + " \(index + 1)",
                            fact: fact
                        )
                    }
                } else {
                    factCard(
                        icon: "🏛️",
                        title: localizationManager.localizedString("История"),
                        fact: countryDetail?.description ?? localizationManager.localizedString("Историческая информация о стране")
                    )
                    
                    factCard(
                        icon: "🎵",
                        title: localizationManager.localizedString("Музыка"),
                        fact: countryDetail?.anthemDescription ?? localizationManager.localizedString("Музыкальная культура страны")
                    )
                    
                    factCard(
                        icon: "🏔️",
                        title: localizationManager.localizedString("Природа"),
                        fact: localizationManager.localizedString("Уникальная природа и ландшафты этой страны")
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    private func getFactIcon(for index: Int) -> String {
        let icons = ["🏛️", "🎵", "🏔️", "🎭", "⚽", "🍽️", "🏺", "🎨", "🔬", "📚"]
        return icons[index % icons.count]
    }
    
    private func factCard(icon: String, title: String, fact: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(fact)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Flag Description Section
    private var flagDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localizedString("Описание флага"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            Text(countryDetail?.flagDescription ?? "")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Anthem Section
    private var anthemSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString("Гимн страны"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                HStack {
                    Button(action: {
                        if audioManager.isPlaying {
                            audioManager.pauseAudio()
                        } else {
                            audioManager.playAnthem(for: countryCode)
                        }
                    }) {
                        if audioManager.isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.5)
                        } else {
                            Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(audioManager.isDownloading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString("Национальный гимн"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(countryDetail?.anthemDescription ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Прогресс-бар
                VStack(spacing: 4) {
                    ProgressView(value: audioManager.currentProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    HStack {
                        Text(audioManager.formatTime(audioManager.currentTime))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(audioManager.formatTime(audioManager.duration))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localizedString("Значение гимна"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(countryDetail?.anthemMeaning ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 20)
                
                // Текст гимна
                if let anthemText = countryDetail?.anthemText, !anthemText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localizedString("Текст гимна"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(anthemText)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Helper Methods
    private func loadCountryDetail() {
        Task { @MainActor in
            isLoadingDetail = true
            countryDetail = await CountryDetailsService.shared.getCountryDetailAsync(for: countryCode)
            isLoadingDetail = false
        }
    }
    

    
    // MARK: - Navigation Methods
    private func navigateToPreviousCountry() {
        guard currentCountryIndex > 0 else { return }
        audioManager.stopAudio()
        currentCountryIndex -= 1
        updateCurrentCountry()
    }
    
    private func navigateToNextCountry() {
        guard currentCountryIndex < allCountries.count - 1 else { return }
        audioManager.stopAudio()
        currentCountryIndex += 1
        updateCurrentCountry()
    }
    
    private func updateCurrentCountry() {
        let country = allCountries[currentCountryIndex]
        // Обновляем данные текущей страны
        countryCode = country.id
        countryName = country.name.common
        flagEmoji = country.flagEmoji
        
        // Перезагружаем детали страны
        loadCountryDetail()
        
        print("Переход к стране: \(country.name.common)")
    }
    
    private func loadAllCountries() {
        // Загружаем список всех стран для навигации
        // Используем существующие данные из CountryService
        Task {
            do {
                let countries = try await CountryService.shared.fetchCountries(for: [.all])
                await MainActor.run {
                    allCountries = countries.sorted { $0.name.common < $1.name.common }
                    
                    // Находим индекс текущей страны
                    if let index = allCountries.firstIndex(where: { $0.id == countryCode }) {
                        currentCountryIndex = index
                    }
                }
            } catch {
                print("Ошибка загрузки стран: \(error)")
            }
        }
    }
}

// MARK: - Photo Gallery Modal (загрузка картинок по URL)
struct PhotoGalleryModal: View {
    let photos: [String]
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(localizationManager.localizedString("Закрыть")) {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    if !photos.isEmpty {
                        Text("\(currentIndex + 1) \(localizationManager.localizedString("of")) \(photos.count)")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding()
                
                TabView(selection: $currentIndex) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, urlString in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                            if let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFit()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white)
                                    case .empty:
                                        ProgressView().tint(.white)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
    }
}

#Preview {
    NavigationView {
        CountryDetailView(countryCode: "AT", countryName: "Австрия", flagEmoji: "🇦🇹")
    }
}
