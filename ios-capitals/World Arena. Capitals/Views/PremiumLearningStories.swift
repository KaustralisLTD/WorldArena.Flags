import SwiftUI

/// Manually paged: the user can read at their own pace, including with larger text.
struct PremiumLearningStories: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var showingScreenshot = false
    @State private var swipingStory = false
    private let stories = ["practice", "countries", "map", "progress"]
    private let images = ["PremiumStoryPractice", "PremiumStoryCountries", "PremiumStoryMap", "PremiumStoryProgress"]
    private func tr(_ key: String) -> String { localization.localizedString(key) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tr("premium.story.headline"))
                .font(.title.bold())
                .fixedSize(horizontal: false, vertical: true)
            Text(tr("premium.story.intro"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 20) { screenshot; description }
                } else {
                    HStack(alignment: .center, spacing: 18) { screenshot; description }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(LinearGradient(colors: [Color.indigo.opacity(0.55), Color.blue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture(minimumDistance: 20).onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) { swipingStory = true }
            }.onEnded { value in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { swipingStory = false }
                guard abs(value.translation.width) > abs(value.translation.height) * 1.5,
                      abs(value.translation.width) > 45 else { return }
                changePage(value.translation.width < 0 ? 1 : -1)
            })
            .accessibilityAction(named: Text(tr("Next"))) { changePage(1) }
            .accessibilityAction(named: Text(tr("Back"))) { changePage(-1) }
            HStack(spacing: 14) {
                Button { changePage(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }
                .disabled(page == 0)
                .accessibilityLabel(tr("Back"))
                .accessibilityIdentifier("premium.story.previous")
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ForEach(0..<stories.count, id: \.self) { index in
                        Capsule().fill(Color.white.opacity(index == page ? 1 : 0.25))
                            .frame(width: index == page ? 22 : 7, height: 7)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(page + 1) / \(stories.count)")
                Spacer(minLength: 0)
                Button { changePage(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }
                .disabled(page == stories.count - 1)
                .accessibilityLabel(tr("Next"))
                .accessibilityIdentifier("premium.story.next")
            }
            .buttonStyle(.plain)
        }
        .foregroundColor(.white)
        .sheetOrFullScreenOnIPad(isPresented: $showingScreenshot) {
            NavigationView {
                Image(images[page])
                    .resizable().scaledToFit()
                    .accessibilityLabel(tr("premium.story.\(stories[page]).title"))
                    .padding()
                    .navigationTitle(tr("premium.story.example"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(tr("Close")) { showingScreenshot = false }
                        }
                    }
            }.navigationViewStyle(.stack)
        }
    }

    private var screenshot: some View {
        Button { if !swipingStory { showingScreenshot = true } } label: {
            Image(images[page])
                .resizable().scaledToFit()
                .frame(width: typeSize.isAccessibilitySize ? 150 : 120, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tr("premium.story.enlarge"))
        .accessibilityIdentifier("premium.story.screenshot")
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: "%02d", page + 1))
                .font(.caption.monospaced().bold())
                .foregroundColor(.cyan)
            Text(tr("premium.story.\(stories[page]).title"))
                .font(.headline)
            Text(tr("premium.story.\(stories[page]).body"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.82))
            Text(tr("premium.story.example"))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.65))
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func changePage(_ direction: Int) {
        let next = min(stories.count - 1, max(0, page + direction))
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { page = next }
    }
}

#if targetEnvironment(simulator)
/// Real screens with non-personal example data, used to capture educational paywall artwork.
struct PremiumScreenshotCapture: View {
    let screen: String
    @EnvironmentObject private var gameState: GameState
    var body: some View {
        NavigationView {
            if screen == "map" {
                WorldProgressMapView()
            } else {
                CountryDetailView(countryCode: "JP", countryName: "Japan", flagEmoji: "🇯🇵")
            }
        }
        .navigationViewStyle(.stack)
    }
}
#endif
