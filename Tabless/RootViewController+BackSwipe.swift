import UIKit

extension RootViewController {

    private var leadingWebViewConstraint: NSLayoutConstraint? {
        return webViewConstraints.first { constraint -> Bool in
            return constraint.firstAttribute == NSLayoutAttribute.leading
        }
    }

    // todo: add shadow to left side of relevant views
    @objc func handleBackSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let viewXTranslation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview).x
        let progress = viewXTranslation / view.bounds.width

        let relevantConstraints = [
            searchLeadingConstraint,
            searchTrailingConstraint,
            leadingWebViewConstraint
        ]

        switch gestureRecognizer.state {
        case .began:
            searchViewSnapshotView.isHidden = false
        case .changed:
            relevantConstraints.forEach { $0?.constant = viewXTranslation }
            searchViewSnapshotView.alpha = 0.4 + 0.6 * progress
        case .cancelled:
            relevantConstraints.forEach { $0?.constant = 0 }
            searchViewSnapshotView.isHidden = true
        case .ended:
            if progress > 0.5 {
                // TODO: animate out webview instead of disappearing
                reset()
            }
            relevantConstraints.forEach { $0?.constant = 0 }
            searchViewSnapshotView.isHidden = true
        default:
            return
        }
    }
}
