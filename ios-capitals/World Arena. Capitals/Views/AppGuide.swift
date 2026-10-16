import SwiftUI
import UIKit

@MainActor
final class AppGuide: ObservableObject {
    static let shared = AppGuide()
    @Published var step: Int? = nil
    static let targets = ["play", "settings", "streak", "fbucks", "friends"]
    var target: String? { step.map { Self.targets[$0] } }
    func start() { step = 0 }
    func finish() {
        step = nil
        UserDefaults.standard.set(false, forKey: "guide.pending")
        UserDefaults.standard.set(true, forKey: "guide.completed")
    }
}
struct GuideAnchors: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}
private struct GuideTarget: ViewModifier {
    let id: String
    @ObservedObject private var guide = AppGuide.shared
    func body(content: Content) -> some View {
        content.anchorPreference(key: GuideAnchors.self, value: .bounds) { [id: $0] }
            .background(GuideScrollTarget(active: guide.target == id))
    }
}
private struct GuideScrollTarget: UIViewRepresentable {
    let active: Bool
    final class Coordinator { var work: DispatchWorkItem?; var active = false }
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ view: UIView, context: Context) {
        guard context.coordinator.active != active else { return }
        context.coordinator.active = active
        context.coordinator.work?.cancel()
        guard active else { return }
        let work = DispatchWorkItem { [weak view] in
            guard let view = view, view.window != nil else { return }
            var parent = view.superview
            while let candidate = parent {
                if let scroll = candidate as? UIScrollView {
                    scroll.scrollRectToVisible(view.convert(view.bounds, to: scroll).insetBy(dx: 0, dy: -50), animated: false)
                    break
                }
                parent = candidate.superview
            }
        }
        context.coordinator.work = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
}
extension View {
    func appGuideTarget(_ id: String) -> some View { modifier(GuideTarget(id: id)) }
}
private struct GuideCardHeight: PreferenceKey {
    static var defaultValue: CGFloat = 240
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
private struct GuideChromeHeights: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
struct AppGuideOverlay: View {
    @State private var contentHeight: CGFloat = 240
    @State private var cardHeight: CGFloat = 340
    @State private var chromeHeights: [String: CGFloat] = [:]
    let anchors: [String: Anchor<CGRect>]
    @ObservedObject private var guide = AppGuide.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private func text(_ key: String) -> String { LocalizationManager.shared.localizedString("guide." + key) }
    var body: some View {
        GeometryReader { geometry in
            if let step = guide.step {
                let target = AppGuide.targets[step]
                let rect = anchors[target].map { geometry[$0] }
                ZStack {
                    Color.black.opacity(0.65)
                        .overlay {
                            if let rect = rect {
                                RoundedRectangle(cornerRadius: 18).fill(Color.white)
                                    .frame(width: rect.width + 8, height: rect.height + 8)
                                    .position(x: rect.midX, y: rect.midY)
                                    .blendMode(.destinationOut)
                            }
                        }.compositingGroup().onTapGesture {}
                    if let rect = rect {
                        RoundedRectangle(cornerRadius: 18).stroke(Color.white, lineWidth: 3)
                            .frame(width: rect.width + 8, height: rect.height + 8)
                            .position(x: rect.midX, y: rect.midY)
                    }
                    let availableHeight = max(120, geometry.size.height - 40)
                    let placeAbove = (rect?.midY ?? 0) >= geometry.size.height / 2
                    let preferredY = rect.map {
                        placeAbove ? $0.minY - 18 - cardHeight / 2 : $0.maxY + 18 + cardHeight / 2
                    } ?? geometry.size.height / 2
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(step + 1) / \(AppGuide.targets.count)")
                                .font(.subheadline.bold()).foregroundColor(.secondary)
                            Spacer()
                            Button(text("skip")) { guide.finish() }
                                .frame(minHeight: 44)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: GuideChromeHeights.self, value: ["header": proxy.size.height])
                        })
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(text(target + ".title")).font(.title2.bold())
                                Text(text(target + ".body"))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(GeometryReader { proxy in
                                Color.clear.preference(key: GuideCardHeight.self, value: proxy.size.height)
                            })
                        }
                        .frame(height: min(contentHeight, max(40, availableHeight - (chromeHeights["header"] ?? 44) - (chromeHeights["footer"] ?? 44) - 97)))
                        .onPreferenceChange(GuideCardHeight.self) { contentHeight = $0 }
                        Divider()
                        HStack(spacing: 16) {
                            if step > 0 {
                                Button(text("back")) { guide.step = step - 1 }
                                    .frame(minHeight: 44)
                            }
                            Spacer(minLength: 8)
                            Button(text(step == 4 ? "done" : "next")) {
                                if step == 4 { guide.finish() } else { guide.step = step + 1 }
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("guide.next")
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .background(GeometryReader { proxy in
                            Color.clear.preference(key: GuideChromeHeights.self, value: ["footer": proxy.size.height])
                        })
                    }
                    .onPreferenceChange(GuideChromeHeights.self) { chromeHeights = $0 }
                    .padding(24)
                    .frame(width: min(440, max(0, geometry.size.width - 40)))
                    .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 24))
                    .background(GeometryReader { proxy in
                        Color.clear
                            .onAppear { cardHeight = proxy.size.height }
                            .onChange(of: proxy.size.height) { cardHeight = $0 }
                    })
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                    .position(x: geometry.size.width / 2,
                              y: max(cardHeight / 2 + 20,
                                     min(geometry.size.height - cardHeight / 2 - 20, preferredY)))
                    .accessibilityElement(children: .contain)
                }

            }
        }
    }
}
struct AppGuideReplay: View {
    var body: some View {
        Button { AppGuide.shared.start() } label: {
            Label(LocalizationManager.shared.localizedString("guide.replay"), systemImage: "sparkles")
                .frame(maxWidth: .infinity).padding(16)
        }.buttonStyle(.bordered).padding(.horizontal, 20)
    }
}
