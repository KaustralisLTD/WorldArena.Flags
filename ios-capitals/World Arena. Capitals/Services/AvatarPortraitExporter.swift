import SwiftUI
#if os(iOS)
import UIKit
#endif

@MainActor
enum AvatarPortraitExporter {
    #if os(iOS)
    /// Экспорт в JPEG для профиля: **квадрат** под рамку в шапке профиля (без полей `scaledToFit`).
    static func jpeg(configuration: AvatarConfiguration) -> Data? {
        let exportS: CGFloat = 360
        let size = CGSize(width: exportS, height: exportS)
        let root = avatarExportRoot(configuration: configuration, exportSize: exportS)

        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: root)
            renderer.scale = UIScreen.main.scale
            renderer.proposedSize = ProposedViewSize(width: exportS, height: exportS)
            if let ui = renderer.uiImage {
                return ui.jpegData(compressionQuality: 0.92)
            }
        }
        return snapshotAvatarJPEGLegacy(root: root, size: size, backgroundUIColor: UIColor(configuration.backgroundColor.color))
    }

    /// Квадратный кадр: фон на весь размер + портретный холст конструктора заполняет квадрат (обрезка как в профиле `scaledToFill`).
    private static func avatarExportRoot(configuration: AvatarConfiguration, exportSize: CGFloat) -> some View {
        let canvasAspectWidthOverHeight: CGFloat = 501 / 684
        return ZStack {
            Rectangle()
                .fill(configuration.backgroundColor.color)
                .frame(width: exportSize, height: exportSize)
            AvatarRendererView(configuration: configuration)
                .aspectRatio(canvasAspectWidthOverHeight, contentMode: .fill)
                .frame(width: exportSize, height: exportSize)
                .clipped()
        }
        .frame(width: exportSize, height: exportSize)
        .clipped()
    }

    private static func snapshotAvatarJPEGLegacy<V: View>(root: V, size: CGSize, backgroundUIColor: UIColor) -> Data? {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return nil
        }
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: -20_000, y: -20_000, width: size.width, height: size.height)
        window.windowLevel = .normal
        window.backgroundColor = backgroundUIColor
        let hosting = UIHostingController(rootView: root)
        hosting.view.bounds = CGRect(origin: .zero, size: size)
        hosting.view.backgroundColor = backgroundUIColor
        window.rootViewController = hosting
        window.isHidden = false
        window.makeKeyAndVisible()
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
        CATransaction.flush()
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        let imgRenderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = imgRenderer.image { _ in
            hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        window.rootViewController = nil
        return image.jpegData(compressionQuality: 0.92)
    }
    #endif

}
