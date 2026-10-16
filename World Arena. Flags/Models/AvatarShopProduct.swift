import SwiftUI

struct AvatarShopProduct: Identifiable {
    enum Slot { case outfit, backdrop, effect, hat }
    let id: String
    let nameKey: String
    let price: Int
    let slot: Slot
    static let catalog: [Self] = [
        .init(id: "cap_1", nameKey: "fbucks.item.traveler_cap", price: 3, slot: .hat),
        .init(id: "shirt_1", nameKey: "fbucks.item.champion_shirt", price: 5, slot: .outfit),
        .init(id: "jacket_1", nameKey: "fbucks.item.explorer_jacket", price: 10, slot: .outfit),
        .init(id: "champion_jacket", nameKey: "fbucks.item.champion_jacket", price: 100, slot: .outfit),
        .init(id: "skin_rainbow", nameKey: "fbucks.item.rainbow_skin", price: 15, slot: .backdrop),
        .init(id: "skin_gold", nameKey: "fbucks.item.gold_skin", price: 20, slot: .backdrop),
        .init(id: "skin_neon", nameKey: "fbucks.item.neon_skin", price: 25, slot: .backdrop),
        .init(id: "effect_fire", nameKey: "fbucks.item.fire_effect", price: 12, slot: .effect),
        .init(id: "effect_stars", nameKey: "fbucks.item.stars_effect", price: 50, slot: .effect)
    ]
    func isEquipped(in c: AvatarConfiguration) -> Bool {
        switch slot {
        case .outfit: return c.shopOutfit == id
        case .backdrop: return c.shopBackdrop == id
        case .effect: return c.shopEffect == id
        case .hat: return c.shopHat == id
        }
    }
    func applying(to original: AvatarConfiguration, remove: Bool = false) -> AvatarConfiguration {
        var c = original
        let value: String? = remove ? nil : id
        switch slot {
        case .outfit: c.shopOutfit = value
        case .backdrop: c.shopBackdrop = value
        case .effect: c.shopEffect = value
        case .hat: c.shopHat = value
        }
        return c
    }
}

/// Vector clothing shares the exact body canvas. It is part of the portrait export,
/// so friends see the same outfit without needing a separate inventory request.
struct AvatarShopGarment: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let champion = id == "champion_jacket"
            let jacket = id != "shirt_1"
            let color: Color = champion ? Color(red: 0.12, green: 0.16, blue: 0.3) : (jacket ? .teal : .indigo)
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.40, y: h * 0.70))
                    p.addQuadCurve(to: CGPoint(x: w * 0.31, y: h * 0.79), control: CGPoint(x: w * 0.32, y: h * 0.74))
                    p.addLine(to: CGPoint(x: w * 0.26, y: h))
                    p.addLine(to: CGPoint(x: w * 0.74, y: h))
                    p.addLine(to: CGPoint(x: w * 0.69, y: h * 0.79))
                    p.addQuadCurve(to: CGPoint(x: w * 0.60, y: h * 0.70), control: CGPoint(x: w * 0.68, y: h * 0.74))
                    p.addQuadCurve(to: CGPoint(x: w * 0.40, y: h * 0.70), control: CGPoint(x: w * 0.50, y: h * 0.72))
                }
                .fill(LinearGradient(colors: [color, color.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                if jacket {
                    Path { p in
                        p.move(to: CGPoint(x: w * 0.5, y: h * 0.79))
                        p.addLine(to: CGPoint(x: w * 0.5, y: h))
                        p.move(to: CGPoint(x: w * 0.4, y: h * 0.70))
                        p.addLine(to: CGPoint(x: w * 0.45, y: h * 0.84))
                        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.79))
                        p.addLine(to: CGPoint(x: w * 0.55, y: h * 0.84))
                        p.addLine(to: CGPoint(x: w * 0.6, y: h * 0.70))
                    }.stroke(champion ? Color.yellow : Color.white.opacity(0.7), lineWidth: w * 0.008)
                }
                Image(systemName: champion ? "crown.fill" : (jacket ? "location.north.fill" : "star.fill"))
                    .font(.system(size: w * 0.07, weight: .bold))
                    .foregroundColor(champion ? .yellow : .white)
                    .position(x: w * (jacket ? 0.60 : 0.5), y: h * 0.88)
            }
        }.accessibilityHidden(true)
    }
}

struct AvatarShopBackdrop: View {
    let configuration: AvatarConfiguration
    var body: some View {
        let colors: [Color] = {
            switch configuration.shopBackdrop {
            case "skin_rainbow": return [.pink, .purple, .cyan]
            case "skin_gold": return [Color(red: 0.35, green: 0.19, blue: 0.05), .yellow, .orange]
            case "skin_neon": return [.indigo, .purple, .cyan]
            default: return [configuration.backgroundColor.color, configuration.backgroundColor.color]
            }
        }()
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct AvatarShopEffect: View {
    let id: String
    var body: some View {
        GeometryReader { g in
            ForEach(0..<6) { i in
                Image(systemName: id == "effect_fire" ? "flame.fill" : "sparkle")
                    .font(.system(size: g.size.width * (i % 2 == 0 ? 0.10 : 0.065)))
                    .foregroundColor(id == "effect_fire" ? .orange : .yellow)
                    .shadow(color: id == "effect_fire" ? .orange : .yellow, radius: 5)
                    .position(x: g.size.width * (i % 2 == 0 ? 0.12 : 0.88), y: g.size.height * (0.25 + Double(i / 2) * 0.26))
            }
        }.accessibilityHidden(true)
    }
}
