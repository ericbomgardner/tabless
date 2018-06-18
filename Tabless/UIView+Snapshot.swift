import UIKit

extension UIView {
    func toSnapshot() -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: frame.width, height: frame.height))
        drawHierarchy(in: CGRect(x: 0, y: 0, width: frame.width, height: frame.height),
                      afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
