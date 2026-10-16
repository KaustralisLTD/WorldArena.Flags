import SwiftUI

struct CapitalPhotoView: View {
    let country: Country
    @State private var photo: CapitalPhotoService.Photo?
    @State private var showingCredits = false

    var body: some View {
        GeometryReader { geometry in
        ZStack(alignment: .bottomTrailing) {
            if let photo {
                Group {
                    if let imageName = photo.imageName {
                        Image(imageName).resizable().scaledToFill()
                    } else {
                        CachedAsyncImage(url: photo.imageURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: { placeholder }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .accessibilityLabel(LocalizationManager.shared.localizedString("Capital photo"))
                Button { showingCredits = true } label: {
                    HStack(spacing: 4) {
                        Text(photo.license ?? "")
                            .lineLimit(1)
                        Image(systemName: "info.circle.fill")
                    }
                        .font(.caption2).padding(6)
                        .foregroundStyle(.white).background(.black.opacity(0.6), in: Capsule())
                }
                .accessibilityLabel(LocalizationManager.shared.localizedString("Photo source and license"))
                .padding(6)
            } else { placeholder }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("capital.photo")
        .sheet(isPresented: $showingCredits) {
            if let photo {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(photo.creator ?? "")
                            Text(photo.license ?? "")
                            Link(LocalizationManager.shared.localizedString("Photo source and license"), destination: photo.sourceURL)
                        }.padding()
                    }
                    .navigationTitle(LocalizationManager.shared.localizedString("Capital photo"))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .task(id: country.id) {
            photo = nil
            let result = await CapitalPhotoService.shared.photo(for: country)
            guard !Task.isCancelled else { return }
            photo = result
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.08)
            Image(systemName: "building.2.crop.circle")
                .font(.largeTitle).foregroundStyle(.secondary)
        }
        .accessibilityLabel(LocalizationManager.shared.localizedString("Capital photo"))
    }
}
