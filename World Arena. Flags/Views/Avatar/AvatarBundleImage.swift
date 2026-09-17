import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Проверка наличия картинки в каталоге (для PNG-слоёв и постепенного наполнения ассетами).
enum AvatarBundleImage {
    static func exists(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #else
        false
        #endif
    }
}
