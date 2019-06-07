import UIKit

// From https://stackoverflow.com/questions/24710258/no-swipe-back-when-hiding-navigation-bar-in-uinavigationcontroller
class InteractivePopRecognizer: NSObject, UIGestureRecognizerDelegate {

    var navigationController: UINavigationController

    init(controller: UINavigationController) {
        self.navigationController = controller
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController.viewControllers.count > 1
    }

    // This is necessary because without it, subviews of your top controller can
    // cancel out your gesture recognizer on the edge.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // TODO: come to a compromise so that the web view's contents don't
        // animate while the edge swipe is happening
        //
        // maybe disable interaction with web view?
        //
        // see https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/coordinating_multiple_gesture_recognizers/preferring_one_gesture_over_another
        return true
    }
}
