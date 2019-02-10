import UIKit

extension WebController {

    // todo: add shadow to left side of relevant views
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
            // todo: add overlay view, start at mostly transparent and move to entirely at ended
        case .cancelled:
            webContainerViewLeadingConstraint?.constant = 0
            webContainerView?.isUserInteractionEnabled = true
        case .ended:
            if progress > 0.5 {
                // TODO: animate out webview instead of disappearing
                reset()
            }
            webContainerViewLeadingConstraint?.constant = 0
            webContainerView?.isUserInteractionEnabled = true
        default:
            return
        }
    }
}
