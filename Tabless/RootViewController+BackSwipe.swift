import UIKit

extension RootViewController {

    // todo: add shadow to left side of relevant views
    @objc func handleBackSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let viewXTranslation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview).x
        let progress = viewXTranslation / view.bounds.width

        switch gestureRecognizer.state {
        case .changed:
            webContainerViewLeadingConstraint?.constant = max(viewXTranslation, 0)
            webContainerView?.isUserInteractionEnabled = false
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
