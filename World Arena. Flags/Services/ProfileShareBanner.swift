
#if os(iOS)
import UIKit
import CoreImage

@MainActor
enum ProfileShareBanner {
    static func render(username: String, level: Int, xp: Int, streak: Int, url: URL, languageCode: String? = nil) -> UIImage {
        let size = CGSize(width: 1080, height: 1600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let L = LocalizationManager.shared
        let languageBundle = languageCode.flatMap { Bundle.main.path(forResource: $0, ofType: "lproj") }.flatMap(Bundle.init(path:))
        @MainActor func localized(_ key: String) -> String {
            languageBundle?.localizedString(forKey: key, value: nil, table: nil) ?? L.localizedString(key)
        }
        return UIGraphicsImageRenderer(size: size, format: format).image { output in
            let context = output.cgContext
            let navy = UIColor(red: 0.025, green: 0.07, blue: 0.15, alpha: 1)
            let teal = UIColor(red: 0.02, green: 0.86, blue: 0.79, alpha: 1)
            let cream = UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)
            let coral = UIColor(red: 1, green: 0.4, blue: 0.3, alpha: 1)
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [navy.cgColor, UIColor(red: 0.02, green: 0.19, blue: 0.24, alpha: 1).cgColor] as CFArray, locations: [0, 1])!
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 1080, y: 1600), options: [])
            context.setStrokeColor(teal.withAlphaComponent(0.12).cgColor)
            context.setLineWidth(2)
            for inset in [0.0, 90.0, 180.0] {
                context.strokeEllipse(in: CGRect(x: 370 + inset, y: -220, width: 800 - 2 * inset, height: 800))
            }
            context.setFillColor(coral.cgColor)
            context.fillEllipse(in: CGRect(x: 928, y: 130, width: 24, height: 24))

            func text(_ value: String, y: CGFloat, height: CGFloat, font: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = cream) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                paragraph.lineBreakMode = .byWordWrapping
                var pointSize = font
                while pointSize > 18 {
                    let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: pointSize, weight: weight), .paragraphStyle: paragraph]
                    let bounds = (value as NSString).boundingRect(with: CGSize(width: 928, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                    if bounds.height <= height { break }
                    pointSize -= 2
                }
                (value as NSString).draw(in: CGRect(x: 76, y: y, width: 928, height: height), withAttributes: [.font: UIFont.systemFont(ofSize: pointSize, weight: weight), .foregroundColor: color, .paragraphStyle: paragraph])
            }
            text(localized("Flags Brand Title").uppercased(), y: 86, height: 100, font: 80, weight: .black)
            text("World Arena", y: 188, height: 50, font: 32, weight: .semibold, color: teal)
            text(localized("Profile Share Headline"), y: 302, height: 194, font: 84, weight: .black)
            text(username, y: 536, height: 74, font: 56, weight: .bold)
            let stats = String(format: localized("Level %d • %d XP • %d-day streak"), level, xp, streak)
            text(stats, y: 622, height: 54, font: 29, color: cream.withAlphaComponent(0.75))

            // A large, centred QR with a full four-module quiet zone and no resampling blur.
            let plate = CGRect(x: 240, y: 736, width: 600, height: 600)
            UIColor.white.setFill()
            UIBezierPath(roundedRect: plate, cornerRadius: 40).fill()
            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(Data(url.absoluteString.utf8), forKey: "inputMessage")
                filter.setValue("M", forKey: "inputCorrectionLevel")
                if let code = filter.outputImage {
                    let modules = Int(code.extent.width)
                    let multiplier = max(1, 520 / (modules + 8))
                    let scaled = code.transformed(by: CGAffineTransform(scaleX: CGFloat(multiplier), y: CGFloat(multiplier)))
                    if let bitmap = CIContext().createCGImage(scaled, from: scaled.extent) {
                        let side = CGFloat(modules * multiplier)
                        context.interpolationQuality = .none
                        UIImage(cgImage: bitmap).draw(in: CGRect(x: (1080 - side) / 2, y: 736 + (600 - side) / 2, width: side, height: side))
                    }
                }
            }
            text(localized("Profile Share CTA"), y: 1390, height: 58, font: 34, weight: .bold, color: teal)
            text(url.host ?? "", y: 1490, height: 48, font: 29, weight: .medium, color: cream.withAlphaComponent(0.8))
        }
    }
}

#endif
