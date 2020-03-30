import UIKit

protocol StateResettable: class {
    func reset()
}

private class StateClearingRequest {
    weak var stateResettable: StateResettable?

    init(stateResettable: StateResettable?) {
        self.stateResettable = stateResettable
    }
}

/// Clears state of each requested StateResettable upon resuming the app if the
/// app was in the background for over `maxBackgroundInterval`
class StateClearer {
    /// Time interval the application is in the background after which state should be cleared
    private static let maxBackgroundInterval: TimeInterval = 60

    private var requests = [StateClearingRequest]()

    private var didEnterBackgroundTime: Date? = nil

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive(notification:)),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground(notification:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    func addStateClearRequest(for stateResettable: StateResettable) {
        let request = StateClearingRequest(stateResettable: stateResettable)
        requests.append(request)
    }

    @objc private func applicationDidBecomeActive(notification: Notification) {
        if let didEnterBackgroundTime = didEnterBackgroundTime {
            let timeIntervalAppWasInBackground = Date().timeIntervalSince(didEnterBackgroundTime)
            if timeIntervalAppWasInBackground > StateClearer.maxBackgroundInterval {
                requests.forEach { request in
                    request.stateResettable?.reset()
                }
            }
        }
        didEnterBackgroundTime = nil
    }

    @objc private func applicationDidEnterBackground(notification: Notification) {
        didEnterBackgroundTime = Date()
    }
}
