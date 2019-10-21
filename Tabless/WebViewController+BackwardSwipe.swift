import UIKit

// TODO: come to a compromise so that the web view's contents don't
// animate while the edge swipe is happening but there aren't any side effects
//
// maybe disable interaction with web view?
//
// see https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/coordinating_multiple_gesture_recognizers/preferring_one_gesture_over_another
extension WebViewController: UIGestureRecognizerDelegate {

    // Prevents web view gesture recognizers from canceling out edge gesture recognizer
    // (inspired by https://stackoverflow.com/a/41248703)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}
