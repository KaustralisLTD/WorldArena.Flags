import SwiftUI
#if os(iOS)
import UIKit
#endif

struct CountryDetailView: View {
    @State var countryCode: String
    @State var countryName: String
    @State var flagEmoji: String
    let navigationCountryCodes: [String]?

    init(countryCode: String, countryName: String, flagEmoji: String, navigationCountryCodes: [String]? = nil) {
        _countryCode = State(initialValue: countryCode)
        _countryName = State(initialValue: countryName)
        _flagEmoji = State(initialValue: flagEmoji)
        self.navigationCountryCodes = navigationCountryCodes
    }

    @StateObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject private var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var countryDetail: CountryDetail?
    @State private var isLoadingDetail = false
    @State private var currentPhotoIndex = 0
    @State private var showingPhotoGallery = false
    @State private var emojiDetailPhoto: CountryPhoto?
    @StateObject private var audioManager = AudioManager.shared
    @State private var allCountries: [Country] = []
    @State private var currentCountryIndex: Int = 0
    @State private var regionDisplayName: String = ""
    @State private var currentAlpha3: String = ""
    @State private var playlistToast: String?
    @State private var previousPlaylistCount: Int = 0

    /// Минимум стран в очереди для старта классики по выбранным флагам.
    private static let learningPlaylistMinCountriesForGame: Int = 6

    private var galleryPhotos: [CountryPhoto] {
        CountryPhotosService.shared.galleryPhotosForLearning(for: countryCode)
    }

    private var isLearned: Bool {
        LearningCountryProgressLogic.isMastered(gameState.learningProgress(forISO2: countryCode))
    }

    private var canGoPrevious: Bool {
        !allCountries.isEmpty && currentCountryIndex > 0
    }

    private var canGoNext: Bool {
        !allCountries.isEmpty && currentCountryIndex < allCountries.count - 1
    }

    private var practicePlaylistSubtitle: String? {
        let n = gameState.learningPracticePlaylistAlpha3.count
        guard n > 0 else { return nil }
        return String(format: localizationManager.localizedString("learning.country.playlist_queue_fmt"), n)
    }

    private var resolvedAlpha3ForPlaylist: String {
        if !currentAlpha3.isEmpty { return currentAlpha3.uppercased() }
        return ISO3166.alpha2ToAlpha3[countryCode.uppercased()]?.uppercased() ?? ""
    }

    private var isCurrentCountryInPracticePlaylist: Bool {
        let id = resolvedAlpha3ForPlaylist
        guard !id.isEmpty else { return false }
        return gameState.learningPracticePlaylistAlpha3.contains(id)
    }

    private var learningPlaylistCount: Int {
        gameState.learningPracticePlaylistAlpha3.count
    }

    private var canStartLearningPlaylistGame: Bool {
        learningPlaylistCount >= Self.learningPlaylistMinCountriesForGame
    }

    private var playlistPlaySubtitle: String? {
        let n = learningPlaylistCount
        guard n > 0, n < Self.learningPlaylistMinCountriesForGame else { return nil }
        return String(
            format: localizationManager.localizedString("learning.country.playlist_min_progress_fmt"),
            n,
            Self.learningPlaylistMinCountriesForGame
        )
    }

    @ViewBuilder
    private var playlistActionBlock: some View {
        VStack(spacing: 12) {
            CountryTrainCTAButton(
                title: isCurrentCountryInPracticePlaylist
                    ? localizationManager.localizedString("learning.country.playlist_status_added")
                    : localizationManager.localizedString("learning.country.train_cta"),
                subtitle: isCurrentCountryInPracticePlaylist ? nil : practicePlaylistSubtitle,
                isInactive: isCurrentCountryInPracticePlaylist,
                action: {
                    if !isCurrentCountryInPracticePlaylist {
                        addCountryToNextGamePlaylist()
                    }
                }
            )
            if !gameState.learningPracticePlaylistAlpha3.isEmpty {
                LearningStudySelectedFlagsButton(
                    title: localizationManager.localizedString("learning.country.playlist_play_cta"),
                    subtitle: playlistPlaySubtitle,
                    isEnabled: canStartLearningPlaylistGame && !gameState.isStartingNewGame,
                    action: startGameWithSelectedPlaylist
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                LearningCountryHeroView(
                    countryCode: countryCode,
                    countryName: countryDetail?.name ?? countryName,
                    flagEmoji: flagEmoji,
                    regionName: regionDisplayName,
                    isLearned: isLearned,
                    isFavorite: gameState.isLearningFavorite(iso2: countryCode),
                    isDifficult: gameState.isLearningCountryDifficult(iso2: countryCode),
                    canGoPrevious: canGoPrevious,
                    canGoNext: canGoNext,
                    onBack: { dismiss() },
                    onPrevious: { navigateToPreviousCountry() },
                    onNext: { navigateToNextCountry() },
                    onToggleFavorite: {
                        learningHaptic()
                        gameState.toggleLearningFavorite(iso2: countryCode)
                    },
                    onToggleDifficult: {
                        learningHaptic()
                        gameState.toggleLearningManualDifficult(iso2: countryCode)
                    }
                )

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 22) {
                            statCardsRow
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 4)

                            photoGallerySection
                            countryInfoGroupedSections
                            interestingFactsSection
                            flagDescriptionSection
                            anthemSection
                            playlistActionBlock
                                .id("learningPlaylistAnchor")
                        }
                        .padding(.top, 4)
                    }
                    .onChange(of: gameState.learningPracticePlaylistAlpha3) { newSet in
                        let newCount = newSet.count
                        let was = previousPlaylistCount
                        previousPlaylistCount = newCount
                        guard was == 0, newCount > 0 else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo("learningPlaylistAnchor", anchor: .bottom)
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(UIColor.systemGroupedBackground))
                        .ignoresSafeArea(.container, edges: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.top, -14)
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = playlistToast {
                Text(msg)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.black.opacity(0.78)))
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: playlistToast)
        .sheet(isPresented: $showingPhotoGallery) {
            PhotoGalleryModal(
                photos: galleryPhotos.map(\.imageURL).filter { !$0.isEmpty },
                currentIndex: $currentPhotoIndex,
                isPresented: $showingPhotoGallery
            )
        }
        .sheet(item: $emojiDetailPhoto) { photo in
            emojiDetailSheet(photo)
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
            previousPlaylistCount = learningPlaylistCount
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
                    if horizontal > 80 {
                        if value.startLocation.x < 80 {
                            dismiss()
                        } else {
                            navigateToPreviousCountry()
                        }
                    } else if horizontal < -80 {
                        navigateToNextCountry()
                    }
                }
        )
    }

    private var statCardsRow: some View {
        HStack(alignment: .top, spacing: 10) {
            CountryStatCardView(
                systemIconName: "building.columns.fill",
                emojiFallback: nil,
                title: localizationManager.localizedString("Столица"),
                value: countryDetail?.capital ?? ""
            )
            CountryStatCardView(
                systemIconName: "person.3.fill",
                emojiFallback: nil,
                title: localizationManager.localizedString("Население"),
                value: countryDetail?.population ?? ""
            )
            CountryStatCardView(
                systemIconName: "ruler",
                emojiFallback: nil,
                title: localizationManager.localizedString("Площадь"),
                value: countryDetail?.area ?? ""
            )
        }
    }

    // MARK: - Gallery

    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizationManager.localizedString("learning.country.gallery.title"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
            Text(localizationManager.localizedString("learning.country.gallery.tap_hint"))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(galleryPhotos.enumerated()), id: \.element.id) { index, photo in
                    learningPhotoTile(photo: photo, index: index)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
    }

    private func learningPhotoTile(photo: CountryPhoto, index: Int) -> some View {
        Button {
            if photo.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                emojiDetailPhoto = photo
            } else {
                let urls = galleryPhotos.map(\.imageURL).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                currentPhotoIndex = max(0, urls.firstIndex(of: photo.imageURL) ?? 0)
                showingPhotoGallery = true
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .frame(height: 96)
                    if photo.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(photo.localImage)
                            .font(.system(size: 40))
                    } else if let u = URL(string: photo.imageURL) {
                        AsyncImage(url: u) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            case .failure:
                                Text(photo.localImage).font(.system(size: 36))
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 96)
                        .clipped()
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )

                Text(photoGalleryCategoryTitle(for: photo.type))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
            }
        }
        .buttonStyle(.plain)
    }

    private func photoGalleryCategoryTitle(for type: PhotoType) -> String {
        switch type {
        case .flag: return localizationManager.localizedString("learning.gallery.tile.flag")
        case .landmark: return localizationManager.localizedString("learning.gallery.tile.landmark")
        case .nature: return localizationManager.localizedString("learning.gallery.tile.nature")
        case .culture: return localizationManager.localizedString("learning.gallery.tile.culture")
        case .government: return localizationManager.localizedString("learning.gallery.tile.government")
        case .coatOfArms: return localizationManager.localizedString("learning.gallery.tile.coat")
        }
    }

    private func emojiDetailSheet(_ photo: CountryPhoto) -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(photo.localImage)
                    .font(.system(size: 88))
                Text(photoGalleryCategoryTitle(for: photo.type))
                    .font(.title2.weight(.semibold))
                if !photo.description.isEmpty {
                    Text(photo.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
            .navigationTitle(localizationManager.localizedString("learning.country.gallery.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString("Закрыть")) {
                        emojiDetailPhoto = nil
                    }
                }
            }
        }
    }

    // MARK: - Info (grouped)

    private var countryInfoGroupedSections: some View {
        VStack(alignment: .leading, spacing: 20) {
            CountryInfoSectionView(
                title: localizationManager.localizedString("learning.country.section.main"),
                rows: [
                    (localizationManager.localizedString("Столица"), countryDetail?.capital ?? ""),
                    (localizationManager.localizedString("learning.country.region"), regionDisplayName),
                    (localizationManager.localizedString("Население"), countryDetail?.population ?? ""),
                    (localizationManager.localizedString("Площадь"), countryDetail?.area ?? "")
                ]
            )
            CountryInfoSectionView(
                title: localizationManager.localizedString("learning.country.section.gov"),
                rows: [
                    (localizationManager.localizedString("Официальный язык"), countryDetail?.officialLanguage ?? ""),
                    (localizationManager.localizedString("Правительство"), countryDetail?.government ?? ""),
                    (localizationManager.localizedString("Глава государства"), countryDetail?.leader ?? "")
                ]
            )
            CountryInfoSectionView(
                title: localizationManager.localizedString("learning.country.section.more"),
                rows: [
                    (localizationManager.localizedString("Телефонный код"), countryDetail?.dialingCode ?? ""),
                    (localizationManager.localizedString("Валюта"), countryDetail?.currency ?? ""),
                    (localizationManager.localizedString("Независимость"), countryDetail?.independence ?? "")
                ]
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localizedString("Описание"))
                    .font(.system(size: 17, weight: .bold))
                Text(countryDetail?.description ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
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

    // MARK: - Practice playlist (следующая классическая игра)

    private func addCountryToNextGamePlaylist() {
        let alpha3: String
        if !currentAlpha3.isEmpty {
            alpha3 = currentAlpha3
        } else if let a3 = ISO3166.alpha2ToAlpha3[countryCode.uppercased()] {
            alpha3 = a3
        } else {
            return
        }
        learningHaptic()
        if gameState.addCountryToLearningPracticePlaylist(alpha3: alpha3) {
            playlistToast = localizationManager.localizedString("learning.country.playlist_added")
        } else {
            playlistToast = localizationManager.localizedString("learning.country.playlist_duplicate")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if playlistToast != nil {
                playlistToast = nil
            }
        }
    }

    /// Классика по странам из очереди «следующая игра».
    private func startGameWithSelectedPlaylist() {
        guard learningPlaylistCount >= Self.learningPlaylistMinCountriesForGame else { return }
        learningHaptic()
        gameState.suppressNextWeeklyWeakSessionRecord = true
        gameState.selectedPlayMode = .classic
        gameState.selectedRegions = [.all]
        Task {
            await gameState.startNewGameWithCurrentRegions()
            await MainActor.run {
                dismiss()
            }
        }
    }

    private func learningHaptic() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func localizedRegion(from api: String) -> String {
        switch api {
        case "Europe": return localizationManager.localizedString("Европа")
        case "Asia": return localizationManager.localizedString("Азия")
        case "Africa": return localizationManager.localizedString("Африка")
        case "Americas": return localizationManager.localizedString("Americas")
        case "Oceania": return localizationManager.localizedString("Океания")
        case "Antarctic": return localizationManager.localizedString("Антарктида")
        default: return api
        }
    }

    private func syncCountryNavigationState() {
        guard !allCountries.isEmpty else {
            currentAlpha3 = ISO3166.alpha2ToAlpha3[countryCode.uppercased()] ?? ""
            return
        }
        if let idx = allCountries.firstIndex(where: {
            $0.countryCode.uppercased() == countryCode.uppercased() || $0.id.uppercased() == countryCode.uppercased()
        }) {
            currentCountryIndex = idx
            let c = allCountries[idx]
            currentAlpha3 = c.id
            regionDisplayName = localizedRegion(from: c.region)
        } else {
            currentAlpha3 = ISO3166.alpha2ToAlpha3[countryCode.uppercased()] ?? ""
        }
    }

    private func loadCountryDetail() {
        Task { @MainActor in
            isLoadingDetail = true
            countryDetail = await CountryDetailsService.shared.getCountryDetailAsync(for: countryCode)
            isLoadingDetail = false
        }
    }

    private func navigateToPreviousCountry() {
        guard canGoPrevious else { return }
        audioManager.stopAudio()
        currentCountryIndex -= 1
        updateCurrentCountry()
    }

    private func navigateToNextCountry() {
        guard canGoNext else { return }
        audioManager.stopAudio()
        currentCountryIndex += 1
        updateCurrentCountry()
    }

    private func updateCurrentCountry() {
        guard !allCountries.isEmpty, currentCountryIndex < allCountries.count else { return }
        let country = allCountries[currentCountryIndex]
        countryCode = country.countryCode
        countryName = country.name.common
        flagEmoji = country.flagEmoji
        currentAlpha3 = country.id
        regionDisplayName = localizedRegion(from: country.region)
        loadCountryDetail()
    }

    private func loadAllCountries() {
        Task {
            do {
                let countries = try await CountryService.shared.fetchCountries(for: [.all])
                await MainActor.run {
                    if let navigationCountryCodes, !navigationCountryCodes.isEmpty {
                        let order = navigationCountryCodes.map { $0.uppercased() }
                        var ordered: [Country] = []
                        for code in order {
                            if let c = countries.first(where: {
                                $0.countryCode.uppercased() == code || $0.id.uppercased() == code
                            }) {
                                ordered.append(c)
                            }
                        }
                        allCountries = ordered
                    } else {
                        allCountries = countries.sorted { $0.name.common < $1.name.common }
                    }
                    syncCountryNavigationState()
                }
            } catch {
                print("Ошибка загрузки стран: \(error)")
            }
        }
    }
}

// MARK: - Photo Gallery Modal

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
            .environmentObject(GameState())
    }
}
