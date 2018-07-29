import UIKit

extension RootViewController {

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil)
    {

        if let alertController = viewControllerToPresent as? UIAlertController,
            alertController.preferredStyle == .actionSheet
        {
            /// Attempt to add an "Open in Safari" action to long-press action sheets
            let customizedAlertController = openInSafariAlertController(from: alertController)
            super.present(customizedAlertController, animated: flag, completion: completion)
            return
        }

        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    private func openInSafariAlertController(from originalAlertController: UIAlertController) -> UIAlertController {
        let customAlertController = UIAlertController(title: originalAlertController.title,
                                                      message: originalAlertController.message,
                                                      preferredStyle: .actionSheet)

        if let firstAction = originalAlertController.actions.first {
            customAlertController.addAction(firstAction)
        }

        if let urlString = originalAlertController.title,
            let url = URL(string: urlString)
        {
            let openInSafariAction = UIAlertAction(title: "Open in Safari",
                                                   style: .default) { _ in
                                                    UIApplication.shared.open(url,
                                                                              options: [:],
                                                                              completionHandler: nil)
            }
            customAlertController.addAction(openInSafariAction)
        }

        for action in originalAlertController.actions.dropFirst() {
            customAlertController.addAction(action)
        }

        return customAlertController
    }
}
