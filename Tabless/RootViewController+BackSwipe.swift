import UIKit

extension RootViewController {

    private var leadingWebViewConstraint: NSLayoutConstraint? {
        return mainView.webViewConstraints.first { constraint -> Bool in
            return constraint.firstAttribute == NSLayoutAttribute.leading
        }
    }

    // todo: add shadow to left side of relevant views
    @objc func handleBackSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let viewXTranslation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview).x
        let progress = viewXTranslation / view.bounds.width

        let relevantConstraints = [
            mainView.searchLeadingConstraint,
            mainView.searchTrailingConstraint,
            leadingWebViewConstraint
        ]

        switch gestureRecognizer.state {
        case .began:
            backSwipeSnapshotView.isHidden = false
        case .changed:
            relevantConstraints.forEach { $0?.constant = viewXTranslation }
            backSwipeSnapshotView.alpha = 0.4 + 0.6 * progress
        case .cancelled:
            relevantConstraints.forEach { $0?.constant = 0 }
            backSwipeSnapshotView.isHidden = true
        case .ended:
            if progress > 0.5 {
                // TODO: animate out webview instead of disappearing
                reset()
            }
            relevantConstraints.forEach { $0?.constant = 0 }
            backSwipeSnapshotView.isHidden = true
        default:
            return
        }
    }

    func setUpBackSwipeSnapshotView() {
        backSwipeSnapshotView.image = view.toSnapshot()
        backSwipeSnapshotView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backSwipeSnapshotView)
        view.sendSubview(toBack: backSwipeSnapshotView)
        backSwipeSnapshotView.pinEdgesToSuperviewEdges()

        backSwipeSnapshotView.isHidden = true
    }

    private func retakeSearchViewSnaphot() {
        backSwipeSnapshotView.image = view.toSnapshot()
    }
}
