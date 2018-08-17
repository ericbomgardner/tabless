import UIKit

extension UITraitCollection {

    /// horizontalSizeClass == .regular
    var isLarge: Bool {
        return horizontalSizeClass == .regular
    }
}
