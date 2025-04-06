import SwiftUI

struct BackgroundView: View {
    @State private var flags: [[Country]] = []
    @State private var offsets: [[CGFloat]] = []
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    private let flagSize = CGSize(width: 60, height: 36)
    private let numberOfRows = 12
    private let flagsPerRow = 10
    private let opacity: Double = 0.12
    private let rowSpacing: CGFloat = 60
    private let flagSpacing: CGFloat = 80
    private let moveSpeed: CGFloat = 1.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackgroundPrimary
                    .edgesIgnoringSafeArea(.all)
                
                // Создаем строки флагов
                ForEach(Array(flags.enumerated()), id: \.0) { rowIndex, rowFlags in
                    // Основная строка
                    HStack(spacing: flagSpacing) {
                        ForEach(Array(zip(rowFlags.indices, rowFlags)), id: \.0) { flagIndex, country in
                            AsyncImage(url: country.flagURL) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: flagSize.width, height: flagSize.height)
                            } placeholder: {
                                Color.clear
                            }
                            .opacity(opacity)
                        }
                    }
                    .offset(x: offsets[rowIndex][0])
                    .rotationEffect(.degrees(-45))
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - CGFloat(rowIndex) * rowSpacing
                    )
                    
                    // Дублирующая строка для непрерывности
                    HStack(spacing: flagSpacing) {
                        ForEach(Array(zip(rowFlags.indices, rowFlags)), id: \.0) { flagIndex, country in
                            AsyncImage(url: country.flagURL) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: flagSize.width, height: flagSize.height)
                            } placeholder: {
                                Color.clear
                            }
                            .opacity(opacity)
                        }
                    }
                    .offset(x: offsets[rowIndex][0] + (geometry.size.width + flagSpacing * CGFloat(flagsPerRow)))
                    .rotationEffect(.degrees(-45))
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - CGFloat(rowIndex) * rowSpacing
                    )
                }
            }
            .onAppear {
                Task {
                    do {
                        let allCountries = try await CountryService.shared.fetchCountries(for: [.all])
                        initializeFlags(with: allCountries)
                        initializeOffsets(width: geometry.size.width)
                    } catch {
                        print("Error loading flags for background: \(error)")
                    }
                }
            }
            .onReceive(timer) { _ in
                updateOffsets(width: geometry.size.width)
            }
        }
    }
    
    private func initializeFlags(with countries: [Country]) {
        flags = (0..<numberOfRows).map { _ in
            Array(countries.shuffled().prefix(flagsPerRow))
        }
    }
    
    private func initializeOffsets(width: CGFloat) {
        offsets = (0..<numberOfRows).map { row in
            let baseOffset = -(width + flagSpacing * CGFloat(flagsPerRow)) / 2
            let staggeredOffset = CGFloat(row) * (width / CGFloat(numberOfRows))
            return [baseOffset + staggeredOffset]
        }
    }
    
    private func updateOffsets(width: CGFloat) {
        let totalWidth = width + flagSpacing * CGFloat(flagsPerRow)
        
        for row in 0..<offsets.count {
            offsets[row][0] += moveSpeed
            
            // Сбрасываем позицию, когда строка проходит половину пути
            if offsets[row][0] > 0 {
                offsets[row][0] -= totalWidth
            }
        }
    }
}

// Безопасный доступ к элементам массива
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    BackgroundView()
} 