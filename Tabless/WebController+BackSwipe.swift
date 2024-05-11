import UIKit

#if !os(visionOS)
extension WebController {

    @objc func handleBackSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let viewXTranslation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview).x
        let progress = viewXTranslation / view.bounds.width

        switch gestureRecognizer.state {
        case .changed:
            webContainerViewLeadingConstraint?.constant = max(viewXTranslation, 0)
            webContainerView?.isUserInteractionEnabled = false
            webContainerView.layer.shadowRadius = 8 * (1 - progress)
            webContainerView.layer.shadowOpacity = Float(0.2 * (1 - progress))
            opacityView.alpha = 0.1 * (1 - progress)
        case .cancelled:
            webContainerViewLeadingConstraint?.constant = 0
            webContainerView?.isUserInteractionEnabled = true
        case .ended:
            let viewXVelocity = gestureRecognizer.velocity(in: gestureRecognizer.view?.superview).x
            if progress > 0.5 || (progress > 0.12 && viewXVelocity > 300) {
                webContainerViewLeadingConstraint?.constant = view.bounds.width
                UIView.animate(withDuration: 0.1,
                               delay: 0,
                               options: .beginFromCurrentState,
                               animations: {
                                self.webContainerView.superview?.layoutIfNeeded()
                                self.opacityView.alpha = 0.0
                               },
                               completion: { _ in self.reset() } )
            } else {
                webContainerViewLeadingConstraint?.constant = 0
                webContainerView?.isUserInteractionEnabled = true
                UIView.animate(withDuration: 0.2,
                               delay: 0,
                               usingSpringWithDamping: 3,
                               initialSpringVelocity: 0.2,
                               options: .beginFromCurrentState,
                               animations: {
                                self.webContainerView.superview?.layoutIfNeeded()
                                self.opacityView.alpha = 0.3
                               },
                               completion: nil)
            }
        default:
            return
        }
    }
}
#endif
