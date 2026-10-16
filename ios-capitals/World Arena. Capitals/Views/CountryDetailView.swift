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
    @Environment(\.presentationMode) private var presentationMode
    @State private var detailTask: Task<Void, Never>?
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

    @State private var galleryPhotos: [CountryPhoto] = []
    @State private var loadingGallery = false

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
        GeometryReader { geometry in
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {


                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 22) {
                LearningCountryHeroView(
                    countryCode: countryCode,
                    countryName: countryName,
                    safeTop: geometry.safeAreaInsets.top,
                    flagEmoji: flagEmoji,
                    regionName: regionDisplayName,
                    isLearned: isLearned,
                    isFavorite: gameState.isLearningFavorite(iso2: countryCode),
                    isDifficult: gameState.isLearningCountryDifficult(iso2: countryCode),
                    canGoPrevious: canGoPrevious,
                    canGoNext: canGoNext,
                    onBack: { presentationMode.wrappedValue.dismiss() },
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
                            statCardsRow
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 4)

                            photoGallerySection
                            editorialIntroduction
                            DisclosureGroup(localizationManager.localizedString("learning.country.section.main")) {
                                countryInfoGroupedSections
                            }.font(.headline).padding(20)
                                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                                .padding(.horizontal, 16)
                            interestingFactsSection
                            flagDescriptionSection
                            anthemSection
                            playlistActionBlock
                                .id("learningPlaylistAnchor")
                        }
                        .padding(.top, 0)
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


            }
        }
        .ignoresSafeArea(.container, edges: .top)
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
                photos: galleryPhotos.filter { !$0.imageURL.isEmpty },
                currentIndex: $currentPhotoIndex,
                isPresented: $showingPhotoGallery
            )
        }
        .sheet(item: $emojiDetailPhoto) { photo in
            emojiDetailSheet(photo)
        }
        .overlay(alignment: .topTrailing) {
            if isLoadingDetail {
                ProgressView().padding().allowsHitTesting(false)
            }
        }
        .task(id: countryCode) {
            galleryPhotos = CountryPhotosService.shared.galleryPhotosForLearning(for: countryCode)
            loadingGallery = true
            let code = countryCode
            let name = CountryLearningCatalog.allCountryInfos.first { $0.code == code }?.name ?? countryName
            let photos = await CountryPhotosService.shared.loadLearningGallery(code: code, englishName: name) { photos in
                guard !Task.isCancelled, code == countryCode else { return }
                galleryPhotos = photos
            }
            guard !Task.isCancelled, code == countryCode else { return }
            galleryPhotos = photos
            loadingGallery = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear {
            previousPlaylistCount = learningPlaylistCount
            loadCountryDetail()
            loadAllCountries()
        }
        .onDisappear {
            audioManager.stopAudio()
            detailTask?.cancel()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    guard abs(horizontal) > abs(vertical) else { return }
                    if horizontal > 80 {
                        if value.startLocation.x < 80 {
                            presentationMode.wrappedValue.dismiss()
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

    private var editorialIntroduction: some View {
        Group {
            if let story = CountryEditorialContent.story(code: countryCode, language: localizationManager.currentLocale.languageCode ?? "en") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localizedString("learning.country.discover"))
                        .font(.title3.weight(.bold))
                    Text(story.text).font(.subheadline).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let url = URL(string: story.url) {
                        Link("Wikipedia · CC BY-SA ↗", destination: url).font(.caption.weight(.medium))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
            }
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

            if loadingGallery { ProgressView().padding(.horizontal, 20) }
            let columns = [GridItem(.adaptive(minimum: 155, maximum: 320), spacing: 14)]
            LazyVGrid(columns: columns, spacing: 18) {
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
                        .frame(height: 160)
                    if photo.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(photo.localImage)
                            .font(.system(size: 40))
                    } else if let u = URL(string: photo.imageURL) {
                        GeometryReader { tile in
                        AsyncImage(url: u) { phase in
                            switch phase {
                            case .success(let img):
                                if photo.type == .flag || photo.type == .coatOfArms {
                                    img.resizable().scaledToFit().padding(12)
                                } else {
                                    img.resizable().scaledToFill()
                                }
                            case .failure:
                                Image(systemName: "photo.badge.exclamationmark").foregroundColor(.secondary)
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: tile.size.width, height: 160)
                        .clipped()
                        }.frame(height: 160)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )

                Text(photo.type == .flag || photo.type == .coatOfArms ? photoGalleryCategoryTitle(for: photo.type) : photo.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            if let facts = CountryReadingLibrary.facts(code: countryCode, language: localizationManager.currentLocale.languageCode ?? "en"), !facts.items.isEmpty {
                Text(localizationManager.localizedString("Интересные факты"))
                    .font(.title3.bold())
                ForEach(Array(facts.items.enumerated()), id: \.offset) { index, fact in
                    factCard(icon: getFactIcon(for: index), title: localizationManager.localizedString("Факт") + " \(index + 1)", fact: fact)
                }
                if let url = URL(string: facts.url) {
                    Link("Wikipedia · CC BY-SA ↗", destination: url).font(.caption)
                    if let extra = facts.extraSource, let extraURL = URL(string: extra) { Link("UNESCO ↗", destination: extraURL).font(.caption) }
                }
            }
        }.padding(20)
    }

    private var anthemStory: CountryAnthemStory? {
        CountryReadingLibrary.anthem(code: countryCode, language: localizationManager.currentLocale.languageCode ?? "en")
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
            if let error = audioManager.playbackError {
                Text(error).font(.footnote).foregroundColor(.secondary).padding(.horizontal, 20)
            }
            Text(localizationManager.localizedString("Гимн страны"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)

            if let credit = AnthemRecordingCredits.all[countryCode.uppercased()] {
                VStack(alignment: .leading, spacing: 6) {
                    if let parent = credit.sharedNationalAnthemOf {
                        let name = localizationManager.currentLocale.localizedString(forRegionCode: parent) ?? parent
                        Text(String(format: localizationManager.localizedString("learning.anthem.shared_fmt"), name))
                    } else if let anthem = credit.anthem { Text(anthem).fontWeight(.semibold) }
                    if let author = credit.author, let license = credit.license { Text("\(author) · \(license)") }
                    if let url = URL(string: credit.source) {
                        Link(localizationManager.localizedString("learning.anthem.recording_source"), destination: url)
                    }
                }.font(.caption).foregroundColor(.secondary).padding(.horizontal, 20)
            }

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
                        Text(anthemStory?.title ?? localizationManager.localizedString("Национальный гимн"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(anthemStory?.text ?? "")
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

                if let excerpt = anthemStory?.excerpt {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localizedString("learning.anthem.excerpt")).font(.headline)
                        Text(excerpt).font(.title3).textSelection(.enabled)
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                }
                if let story = anthemStory, let url = URL(string: story.url) {
                    Link(destination: url) {
                        HStack {
                            Text(localizationManager.localizedString("learning.anthem.full_lyrics_source"))
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }.font(.headline).padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }.padding(.horizontal, 20)
                    Text(story.attribution ?? "Wikipedia · CC BY-SA").font(.caption).foregroundColor(.secondary).padding(.horizontal, 20)
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
                presentationMode.wrappedValue.dismiss()
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
        detailTask?.cancel()
        countryName = CountryDetailsService.shared.getLocalizedCountryName(for: countryCode)
        countryDetail = CountryDetailsService.shared.getCountryDetail(for: countryCode)
        detailTask = Task { @MainActor in
            isLoadingDetail = true
            let requestedCode = countryCode
            let detail = await CountryDetailsService.shared.getCountryDetailAsync(for: requestedCode)
            guard !Task.isCancelled, requestedCode == countryCode else { return }
            countryDetail = detail
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
        countryName = CountryDetailsService.shared.getLocalizedCountryName(for: country.countryCode)
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
    let photos: [CountryPhoto]
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
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                            if let url = URL(string: photo.imageURL) {
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
                if photos.indices.contains(currentIndex) {
                    let photo = photos[currentIndex]
                    if let source = photo.sourceURL, let url = URL(string: source) {
                        VStack(spacing: 6) {
                            Text(photo.displayTitle.replacingOccurrences(of: "_", with: " ")).font(.headline).lineLimit(3)
                            if !photo.displayStory.isEmpty {
                                ScrollView { Text(photo.displayStory).font(.subheadline).fixedSize(horizontal: false, vertical: true) }.frame(maxHeight: 160)
                            }
                            if let article = photo.articleURL, let articleURL = URL(string: article) {
                                Link("Wikipedia · CC BY-SA ↗", destination: articleURL).font(.caption).foregroundColor(.cyan)
                            }
                            Text(photo.description).font(.caption2).lineLimit(4)
                            Link("Wikimedia Commons ↗", destination: url).font(.caption.bold()).foregroundColor(.cyan)
                        }
                        .foregroundColor(.white).padding()
                    }
                }
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
