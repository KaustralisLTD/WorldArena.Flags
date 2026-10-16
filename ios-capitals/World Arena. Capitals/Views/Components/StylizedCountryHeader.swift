import SwiftUI

// MARK: - Stylized Country Header
struct StylizedCountryHeader: View {
    let countryCode: String
    let countryName: String
    let flagEmoji: String
    let onBack: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    private var headerStyle: CountryHeaderStyle {
        CountryHeaderStyles.getHeaderStyle(for: countryCode)
    }
    
    var body: some View {
        ZStack {
            // Background with country-specific styling
            backgroundLayer
            
            // Decorative elements
            decorativeLayer
            
            // Content layer
            contentLayer
        }
        .frame(height: 280)
        .ignoresSafeArea(.container, edges: .top)
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Main gradient background
            LinearGradient(
                colors: headerStyle.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Flag emoji as background element
            flagBackgroundElement
        }
    }
    
    // MARK: - Flag Background Element
    private var flagBackgroundElement: some View {
        Group {
            switch headerStyle.flagPosition {
            case .topLeading:
                VStack {
                    HStack {
                        Text(flagEmoji)
                            .font(.system(size: 200))
                            .opacity(0.15)
                            .offset(x: -30, y: -20)
                        Spacer()
                    }
                    Spacer()
                }
                
            case .topCenter:
                VStack {
                    Text(flagEmoji)
                        .font(.system(size: 200))
                        .opacity(0.15)
                        .offset(y: -30)
                    Spacer()
                }
                
            case .topTrailing:
                VStack {
                    HStack {
                        Spacer()
                        Text(flagEmoji)
                            .font(.system(size: 200))
                            .opacity(0.15)
                            .offset(x: 30, y: -20)
                    }
                    Spacer()
                }
                
            case .center:
                Text(flagEmoji)
                    .font(.system(size: 300))
                    .opacity(0.12)
                    .scaleEffect(1.5)
                    .blur(radius: 0.5)
            }
        }
    }
    
    // MARK: - Decorative Layer
    private var decorativeLayer: some View {
        ZStack {
            ForEach(Array(headerStyle.decorativeElements.enumerated()), id: \.offset) { index, element in
                decorativeElement(element)
                    .opacity(0.3)
            }
        }
    }
    
    // MARK: - Decorative Element Renderer
    @ViewBuilder
    private func decorativeElement(_ element: DecorativeElement) -> some View {
        switch element {
        case .stars(let count, let color, let size):
            starsPattern(count: count, color: color, size: size)
            
        case .horizontalStripes(let count):
            horizontalStripesPattern(count: count)
            
        case .verticalStripes(let count):
            verticalStripesPattern(count: count)
            
        case .crosses(let style):
            crossesPattern(style: style)
            
        case .elegantBorder:
            elegantBorderPattern()
            
        case .geometricPattern:
            geometricPattern()
            
        case .romanPattern:
            romanPattern()
            
        case .heraldic:
            heraldicPattern()
            
        case .orthodoxCross:
            orthodoxCrossPattern()
            
        case .chinesePattern:
            chinesePattern()
            
        case .risingSum:
            risingSunPattern()
            
        case .sakura:
            sakuraPattern()
            
        case .mapleLeaf:
            mapleLeafPattern()
            
        case .southernCross:
            southernCrossPattern()
            
        case .diamond:
            diamondPattern()
            
        case .chakra:
            chakraPattern()
            
        case .aztecPattern:
            aztecPattern()
            
        case .sun:
            sunPattern()
            
        case .eagle:
            eaglePattern()
            
        case .rainbow:
            rainbowPattern()
            
        case .protea:
            proteaPattern()
            
        case .africanPattern:
            africanPattern()
            
        case .masaiShield:
            masaiShieldPattern()
            
        case .star(let color):
            starPattern(color: color)
            
        case .islamicPattern:
            islamicPattern()
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Pattern Implementations
    
    private func starsPattern(count: Int, color: Color, size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundColor(color)
                    .position(
                        x: CGFloat.random(in: 50...300),
                        y: CGFloat.random(in: 50...200)
                    )
            }
        }
    }
    
    private func horizontalStripesPattern(count: Int) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                Rectangle()
                    .fill(index % 2 == 0 ? headerStyle.primaryColor : headerStyle.secondaryColor)
                    .opacity(0.2)
                    .frame(height: 280 / CGFloat(count))
            }
        }
    }
    
    private func verticalStripesPattern(count: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                Rectangle()
                    .fill(index % 2 == 0 ? headerStyle.primaryColor : headerStyle.secondaryColor)
                    .opacity(0.2)
            }
        }
    }
    
    private func crossesPattern(style: CrossStyle) -> some View {
        ZStack {
            switch style {
            case .diagonal:
                // Диагональные кресты
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 400, y: 280))
                    path.move(to: CGPoint(x: 400, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 280))
                }
                .stroke(headerStyle.accentColor, lineWidth: 3)
                
            case .straight:
                // Прямые кресты
                Path { path in
                    path.move(to: CGPoint(x: 200, y: 0))
                    path.addLine(to: CGPoint(x: 200, y: 280))
                    path.move(to: CGPoint(x: 0, y: 140))
                    path.addLine(to: CGPoint(x: 400, y: 140))
                }
                .stroke(headerStyle.accentColor, lineWidth: 4)
            }
        }
    }
    
    private func elegantBorderPattern() -> some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(
                LinearGradient(
                    colors: [headerStyle.accentColor, headerStyle.primaryColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .padding(20)
    }
    
    private func geometricPattern() -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .stroke(headerStyle.accentColor, lineWidth: 1)
                    .frame(width: CGFloat(30 + index * 20))
                    .position(
                        x: CGFloat(100 + index * 25),
                        y: CGFloat(50 + index * 15)
                    )
            }
        }
    }
    
    private func romanPattern() -> some View {
        HStack(spacing: 20) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(headerStyle.accentColor)
                    .frame(width: 4, height: 60)
            }
        }
        .position(x: 200, y: 50)
    }
    
    private func heraldicPattern() -> some View {
        Image(systemName: "shield.fill")
            .font(.system(size: 40))
            .foregroundColor(headerStyle.accentColor)
            .position(x: 300, y: 80)
    }
    
    private func orthodoxCrossPattern() -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(headerStyle.accentColor)
                .frame(width: 4, height: 30)
            Rectangle()
                .fill(headerStyle.accentColor)
                .frame(width: 25, height: 4)
            Rectangle()
                .fill(headerStyle.accentColor)
                .frame(width: 4, height: 20)
            Rectangle()
                .fill(headerStyle.accentColor)
                .frame(width: 20, height: 3)
            Rectangle()
                .fill(headerStyle.accentColor)
                .frame(width: 4, height: 15)
        }
        .position(x: 320, y: 100)
    }
    
    private func chinesePattern() -> some View {
        ZStack {
            // Основная звезда
            Image(systemName: "star.fill")
                .font(.system(size: 25))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                .position(x: 120, y: 80)
            
            // Четыре маленькие звезды
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .position(
                        x: 150 + CGFloat(index * 15),
                        y: 60 + CGFloat(index % 2 * 20)
                    )
            }
        }
    }
    
    private func risingSunPattern() -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [headerStyle.secondaryColor, headerStyle.secondaryColor.opacity(0.3)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .position(x: 200, y: 140)
        }
    }
    
    private func sakuraPattern() -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.pink.opacity(0.6))
                    .rotationEffect(.degrees(Double(index * 60)))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 50...230)
                    )
            }
        }
    }
    
    private func mapleLeafPattern() -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 30))
            .foregroundColor(headerStyle.primaryColor)
            .position(x: 200, y: 140)
    }
    
    private func southernCrossPattern() -> some View {
        ZStack {
            // Созвездие Южного Креста
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
                    .position(
                        x: 280 + CGFloat([0, 10, 20, 5, 15][index]),
                        y: 100 + CGFloat([0, 15, 30, 8, 22][index])
                    )
            }
        }
    }
    
    private func diamondPattern() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 200, y: 80))
            path.addLine(to: CGPoint(x: 250, y: 140))
            path.addLine(to: CGPoint(x: 200, y: 200))
            path.addLine(to: CGPoint(x: 150, y: 140))
            path.closeSubpath()
        }
        .stroke(headerStyle.secondaryColor, lineWidth: 3)
    }
    
    private func chakraPattern() -> some View {
        ZStack {
            Circle()
                .stroke(headerStyle.accentColor, lineWidth: 2)
                .frame(width: 40, height: 40)
            
            ForEach(0..<24, id: \.self) { index in
                Rectangle()
                    .fill(headerStyle.accentColor)
                    .frame(width: 1, height: 15)
                    .offset(y: -12.5)
                    .rotationEffect(.degrees(Double(index) * 15))
            }
        }
        .position(x: 200, y: 140)
    }
    
    private func aztecPattern() -> some View {
        ZStack {
            // Стилизованный ацтекский орел
            Image(systemName: "bird.fill")
                .font(.system(size: 25))
                .foregroundColor(headerStyle.secondaryColor)
            
            // Кактус
            VStack(spacing: 2) {
                Rectangle()
                    .fill(headerStyle.primaryColor)
                    .frame(width: 6, height: 20)
                Rectangle()
                    .fill(headerStyle.primaryColor)
                    .frame(width: 10, height: 4)
            }
            .offset(y: 15)
        }
        .position(x: 200, y: 140)
    }
    
    private func sunPattern() -> some View {
        ZStack {
            // Солнце
            Circle()
                .fill(headerStyle.accentColor)
                .frame(width: 40, height: 40)
            
            // Лучи
            ForEach(0..<16, id: \.self) { index in
                Rectangle()
                    .fill(headerStyle.accentColor)
                    .frame(width: 2, height: 15)
                    .offset(y: -27.5)
                    .rotationEffect(.degrees(Double(index) * 22.5))
            }
        }
        .position(x: 200, y: 140)
    }
    
    private func eaglePattern() -> some View {
        Image(systemName: "bird.fill")
            .font(.system(size: 30))
            .foregroundColor(headerStyle.accentColor)
            .position(x: 200, y: 140)
    }
    
    private func rainbowPattern() -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Path { path in
                    path.addArc(
                        center: CGPoint(x: 200, y: 280),
                        radius: CGFloat(100 - index * 10),
                        startAngle: .degrees(0),
                        endAngle: .degrees(180),
                        clockwise: false
                    )
                }
                .stroke([.red, .orange, .yellow, .green, .blue, .purple][index], lineWidth: 3)
            }
        }
    }
    
    private func proteaPattern() -> some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 25))
            .foregroundColor(.pink)
            .position(x: 200, y: 140)
    }
    
    private func africanPattern() -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { col in
                        Circle()
                            .fill(headerStyle.primaryColor)
                            .frame(width: 6, height: 6)
                    }
                }
                .position(x: 200, y: CGFloat(100 + row * 20))
            }
        }
    }
    
    private func masaiShieldPattern() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 200, y: 100))
            path.addLine(to: CGPoint(x: 180, y: 120))
            path.addLine(to: CGPoint(x: 180, y: 180))
            path.addLine(to: CGPoint(x: 200, y: 200))
            path.addLine(to: CGPoint(x: 220, y: 180))
            path.addLine(to: CGPoint(x: 220, y: 120))
            path.closeSubpath()
        }
        .fill(headerStyle.primaryColor)
        .overlay(
            Path { path in
                path.move(to: CGPoint(x: 185, y: 140))
                path.addLine(to: CGPoint(x: 215, y: 140))
                path.move(to: CGPoint(x: 185, y: 160))
                path.addLine(to: CGPoint(x: 215, y: 160))
            }
            .stroke(headerStyle.accentColor, lineWidth: 2)
        )
    }
    
    private func starPattern(color: Color) -> some View {
        Image(systemName: "star.fill")
            .font(.system(size: 30))
            .foregroundColor(color)
            .position(x: 200, y: 140)
    }
    
    private func islamicPattern() -> some View {
        ZStack {
            // Полумесяц
            Path { path in
                path.addArc(center: CGPoint(x: 200, y: 140), radius: 20, startAngle: .degrees(45), endAngle: .degrees(315), clockwise: false)
                path.addArc(center: CGPoint(x: 205, y: 135), radius: 15, startAngle: .degrees(225), endAngle: .degrees(45), clockwise: true)
            }
            .fill(headerStyle.secondaryColor)
            
            // Звезда
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(headerStyle.secondaryColor)
                .position(x: 225, y: 125)
        }
    }
    
    // MARK: - Content Layer
    private var contentLayer: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top section with navigation (отступ сверху с учётом safe area — кнопка «Назад» не перекрывает часы)
                VStack(spacing: 16) {
                    // Navigation buttons
                    HStack {
                        // Back button - опущена ниже, чтобы не перекрывать часы
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Navigation arrows
                        HStack(spacing: 12) {
                            Button(action: onPrevious) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: onNext) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geo.safeAreaInsets.top + 100) // Значительно увеличен отступ сверху, чтобы кнопки не перекрывали часы
                
                Spacer()
                
                // Country title
                VStack(spacing: 8) {
                    Text(flagEmoji)
                        .font(.system(size: 50))
                        .scaleEffect(1.2)
                    
                    Text(countryName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: headerStyle.textShadow ? .black.opacity(0.5) : .clear, radius: 2, x: 1, y: 1)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preview
struct StylizedCountryHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StylizedCountryHeader(
                countryCode: "US",
                countryName: "United States",
                flagEmoji: "🇺🇸",
                onBack: {},
                onPrevious: {},
                onNext: {}
            )
            
            StylizedCountryHeader(
                countryCode: "FR",
                countryName: "France",
                flagEmoji: "🇫🇷",
                onBack: {},
                onPrevious: {},
                onNext: {}
            )
            
            StylizedCountryHeader(
                countryCode: "JP",
                countryName: "Japan",
                flagEmoji: "🇯🇵",
                onBack: {},
                onPrevious: {},
                onNext: {}
            )
        }
        .previewLayout(.sizeThatFits)
    }
}

