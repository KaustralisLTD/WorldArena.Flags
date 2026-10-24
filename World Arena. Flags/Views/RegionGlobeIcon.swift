import SwiftUI

/// Uses the approved globe atlas and the same easing/timing as the Remotion preview.
/// Selection belongs to the caller, so several continents can stay enlarged together.
struct RegionGlobeIcon: View {
    let region: GameState.Region
    let isSelected: Bool
    var size: CGFloat = 76
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var atlasIndex: Int? {
        switch region {
        case .all: return 0
        case .europe: return 1
        case .asia: return 2
        case .africa: return 3
        case .northAmerica: return 4
        case .southAmerica: return 5
        case .oceania: return 6
        case .myMistakes: return nil
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(isSelected ? 0.25 : 0))
                .blur(radius: size * 0.12)
            if let index = atlasIndex {
                Image("RegionEarthAtlas")
                    .resizable()
                    .frame(width: size * 4, height: size * 2)
                    .offset(x: -CGFloat(index % 4) * size, y: -CGFloat(index / 4) * size)
                    .frame(width: size, height: size, alignment: .topLeading)
                    .clipped()
                    .shadow(color: .black.opacity(0.22), radius: 5, y: 4)
                    .scaleEffect(reduceMotion ? 1 : (isSelected ? 1.17 : 0.90))
                    .offset(y: reduceMotion ? 0 : (isSelected ? -2 : 2))
            } else {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: size * 0.65))
                    .foregroundStyle(isSelected ? Color.white : Color.orange)
            }
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? nil : .timingCurve(0.22, 1, 0.36, 1, duration: 0.65), value: isSelected)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
