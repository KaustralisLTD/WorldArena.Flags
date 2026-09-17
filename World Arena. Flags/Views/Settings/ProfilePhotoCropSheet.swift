#if os(iOS)
import SwiftUI
import UIKit

// MARK: - Image helpers

enum ProfilePhotoImportHelpers {
    static func downsample(_ image: UIImage, maxPixel: CGFloat = 1600) -> UIImage {
        profilePhotoDownsample(image, maxPixel: maxPixel)
    }
}

private func profilePhotoDownsample(_ image: UIImage, maxPixel: CGFloat = 1600) -> UIImage {
    let w = image.size.width * image.scale
    let h = image.size.height * image.scale
    let maxSide = max(w, h)
    guard maxSide > maxPixel else { return image }
    let r = maxPixel / maxSide
    let newSize = CGSize(width: floor(w * r), height: floor(h * r))
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}

private func profilePhotoResizeMaxDimension(_ image: UIImage, maxPx: CGFloat) -> UIImage {
    let pxW = image.size.width * image.scale
    let pxH = image.size.height * image.scale
    let m = max(pxW, pxH)
    guard m > maxPx else { return image }
    let r = maxPx / m
    let newSz = CGSize(width: floor(pxW * r), height: floor(pxH * r))
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: newSz, format: format)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSz))
    }
}

// MARK: - Export (same layout as interactive crop)

private struct ProfilePhotoCropExportView: View {
    let image: UIImage
    /// Сторона квадратного кадра (итоговое фото — квадрат, без круглой маски и белых углов в JPEG).
    let cropSide: CGFloat
    let coverScale: CGFloat
    let pinch: CGFloat
    let offset: CGSize

    private var total: CGFloat { coverScale * pinch }

    var body: some View {
        let w = image.size.width * total
        let h = image.size.height * total
        Image(uiImage: image)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(width: w, height: h)
            .offset(offset)
            .frame(width: cropSide, height: cropSide)
            .clipped()
    }
}

// MARK: - Sheet

@available(iOS 16.0, *)
struct ProfilePhotoCropSheet: View {
    private let sourceImage: UIImage
    let onCancel: () -> Void
    let onComplete: (Data) -> Void

    private let cropSide: CGFloat = 300

    private var image: UIImage { sourceImage }

    /// Покрытие квадрата кадра
    @State private var pinch: CGFloat = 1
    @State private var livePinch: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var dragStart: CGSize = .zero

    private var coverScale: CGFloat {
        let iw = image.size.width
        let ih = image.size.height
        guard iw > 0, ih > 0 else { return 1 }
        return max(cropSide / iw, cropSide / ih)
    }

    private var totalScale: CGFloat { coverScale * pinch * livePinch }

    private var displayWidth: CGFloat { image.size.width * totalScale }
    private var displayHeight: CGFloat { image.size.height * totalScale }

    private let lm = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 18) {
                    Text(lm.localizedString("profile_crop_photo_subtitle"))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)

                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: displayWidth, height: displayHeight)
                            .offset(offset)
                            .frame(width: cropSide, height: cropSide)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.95), .cyan.opacity(0.5), .purple.opacity(0.65)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: .black.opacity(0.45), radius: 16, y: 8)
                    }
                    .frame(width: cropSide, height: cropSide)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { v in
                                    livePinch = v
                                    clampOffset()
                                }
                                .onEnded { _ in
                                    pinch = min(4, max(1, pinch * livePinch))
                                    livePinch = 1
                                    clampOffset()
                                },
                            DragGesture()
                                .onChanged { g in
                                    offset = CGSize(
                                        width: dragStart.width + g.translation.width,
                                        height: dragStart.height + g.translation.height
                                    )
                                    clampOffset()
                                }
                                .onEnded { _ in
                                    dragStart = offset
                                }
                        )
                    )

                    Spacer(minLength: 12)

                    Text(lm.localizedString("profile_crop_zoom_label"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))

                    Slider(
                        value: Binding(
                            get: { Double(pinch) },
                            set: { newVal in
                                pinch = CGFloat(min(4, max(1, newVal)))
                                clampOffset()
                            }
                        ),
                        in: 1...4,
                        step: 0.02
                    )
                    .tint(.cyan)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle(lm.localizedString("profile_crop_photo_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.localizedString("profile_crop_cancel")) {
                        onCancel()
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.localizedString("profile_crop_done")) {
                        exportJPEG()
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pinch = 1
            livePinch = 1
            offset = .zero
            dragStart = .zero
        }
    }

    init(image: UIImage, onCancel: @escaping () -> Void, onComplete: @escaping (Data) -> Void) {
        self.sourceImage = ProfilePhotoImportHelpers.downsample(image)
        self.onCancel = onCancel
        self.onComplete = onComplete
    }

    private func clampOffset() {
        let w = displayWidth
        let h = displayHeight
        let s = cropSide
        let maxX = max(0, (w - s) / 2)
        let maxY = max(0, (h - s) / 2)
        offset.width = min(maxX, max(-maxX, offset.width))
        offset.height = min(maxY, max(-maxY, offset.height))
    }

    private func exportJPEG() {
        let export = ProfilePhotoCropExportView(
            image: image,
            cropSide: cropSide,
            coverScale: coverScale,
            pinch: pinch,
            offset: offset
        )
        .frame(width: cropSide, height: cropSide)

        let renderer = ImageRenderer(content: export)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(width: cropSide, height: cropSide)

        guard let ui = renderer.uiImage else {
            onCancel()
            return
        }
        let scaled = profilePhotoResizeMaxDimension(ui, maxPx: 512)
        guard let data = scaled.jpegData(compressionQuality: 0.88) else {
            onCancel()
            return
        }
        onComplete(data)
    }
}

#endif
