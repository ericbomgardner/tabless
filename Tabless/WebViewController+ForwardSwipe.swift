import UIKit

extension WebViewController {

    private var commitCutoff: CGFloat {
        return 0.5
    }

    // TODO: Make this have spring resistance and add background "Open in Safari" thing
    @objc func handleForwardSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let viewXTranslation = gestureRecognizer.translation(in: gestureRecognizer.view?.superview).x
        let progress = abs(viewXTranslation) / view.bounds.width

        switch gestureRecognizer.state {
        case .changed:
            updateConstraintConstant(viewXTranslation: viewXTranslation)
            webContainerView.isUserInteractionEnabled = false
            webContainerView.layer.shadowRadius = 8 * (1 - progress)
            webContainerView.layer.shadowOpacity = Float(0.2 * (1 - progress))
            updateLabelAlpha(viewXTranslation: viewXTranslation)
        case .cancelled:
            webContainerViewLeadingConstraint?.constant = 0
            webContainerView.isUserInteractionEnabled = true
        case .ended:
            if progress > commitCutoff {
                self.gestureCompleted()
            } else {
                webContainerViewLeadingConstraint?.constant = 0
                openInSafariLabel.alpha = 0
                webContainerView.isUserInteractionEnabled = true
                UIView.animate(withDuration: 0.2,
                               delay: 0,
                               usingSpringWithDamping: 3,
                               initialSpringVelocity: 0.2,
                               options: .beginFromCurrentState,
                               animations: {
                                self.webContainerView.superview?.layoutIfNeeded()
                               },
                           completion: nil)
            }
        default:
            return
        }
    }

    private func updateConstraintConstant(viewXTranslation: CGFloat) {
        // x = y + y^2 / n
        // y = n/2 - sqrt(n) * sqrt(n/4 + x)
        let constant = 64 - sqrt(128) * sqrt(32 + max(0, -viewXTranslation))
        webContainerViewLeadingConstraint?.constant = constant
    }

    private func updateLabelAlpha(viewXTranslation: CGFloat) {
        let alpha = max(0, min((-viewXTranslation - 50) / (webContainerView.frame.width * commitCutoff - 50), 1))
        openInSafariLabel.alpha = alpha
    }

    private func gestureCompleted() {
        if let url = webContainerView.webView.url {
            UIApplication.shared.open(url, options: [:], completionHandler: { [weak self] _ in
                self?.openInSafariLabel.alpha = 0
                self?.webContainerViewLeadingConstraint?.constant = 0
                self?.webContainerView.isUserInteractionEnabled = true
                self?.webContainerView.superview?.layoutIfNeeded()
            })
        }
    }
}
