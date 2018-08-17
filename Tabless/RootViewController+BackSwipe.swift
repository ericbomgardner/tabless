import UIKit

extension RootViewController {

    // todo: add shadow to left side of relevant views
    @objc func handleBackSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let viewXTranslation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview).x
        let progress = viewXTranslation / view.bounds.width

        switch gestureRecognizer.state {
        case .changed:
            webContainerViewLeadingConstraint?.constant = viewXTranslation
//            backSwipeSnapshotView.alpha = 0.4 + 0.6 * progress
        case .cancelled:
            webContainerViewLeadingConstraint?.constant = 0
        case .ended:
            if progress > 0.5 {
                // TODO: animate out webview instead of disappearing
                reset()
            }
            webContainerViewLeadingConstraint?.constant = 0
        default:
            return
        }
    }
}
