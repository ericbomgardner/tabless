import UIKit

protocol StateResettable: AnyObject {
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
    ///
    /// Sadly, iOS 13 seems to have limited background time to 30 seconds, so we likely won't
    /// user this interval unless iOS unrestricts or further restricts the background time
    private static let desiredClearInterval: TimeInterval = 60

    /// Since we have a limited time in the background, it's possible we won't be able to wait
    /// the full `desiredClearInterval` -- this interval is used as the minimum interval
    /// that we deem acceptable to use as the clear interval if the amount of background time
    /// we're allotted is less than `desiredClearInterval`.
    ///
    /// This interval is designed to fit under the iOS 13 background time of 30 seconds -- despite
    /// how much greated `desiredClearInterval` is than this value, the better UX of a
    /// background clear makes it worth dealing with clears happening sooner than is ideal.
    private static let minimumAcceptableBackgroundClearInterval: TimeInterval = 25

    private var requests = [StateClearingRequest]()

    private var didEnterBackgroundTime: Date? = nil
    private var backgroundTask: UIBackgroundTaskIdentifier? = nil
    private var didPerformStateClearRequests = false

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive(notification:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive(notification:)),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(notification:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }

    func addStateClearRequest(for stateResettable: StateResettable) {
        let request = StateClearingRequest(stateResettable: stateResettable)
        requests.append(request)
    }

    private func performStateClearRequests() {
        requests.forEach { request in
            request.stateResettable?.reset()
        }
        didPerformStateClearRequests = true
    }

    @objc private func applicationDidBecomeActive(notification: Notification) {
        // If we weren't able to clear state in the background but should clear
        // state, clear it in the foreground instead.
        //
        // This foreground clear is visually less satisfying, since the old
        // (pre-clear) UI is displayed for longer -- we should make every effort
        // to clear state in the background!
        if let didEnterBackgroundTime = didEnterBackgroundTime,
            !didPerformStateClearRequests
        {
            let timeIntervalAppWasInBackground = Date().timeIntervalSince(didEnterBackgroundTime)
            if timeIntervalAppWasInBackground > StateClearer.desiredClearInterval {
                DebugLogger.log(
                    "Foreground cleared after \(timeIntervalAppWasInBackground) seconds")
                performStateClearRequests()
            }
        }
        didEnterBackgroundTime = nil
        didPerformStateClearRequests = false
    }

    @objc private func applicationWillResignActive(notification: Notification) {
        startBackgroundTask()
    }

    @objc private func applicationDidEnterBackground(notification: Notification) {
        didEnterBackgroundTime = Date()
        startBackgroundTask()
    }

    private func startBackgroundTask() {
        let endBackgroundTask = { [weak self] in
            guard let backgroundTask = self?.backgroundTask else {
                return
            }
            UIApplication.shared.endBackgroundTask(backgroundTask)
            self?.backgroundTask = nil
        }

        let taskExpirationHandler = endBackgroundTask
        backgroundTask =
            UIApplication.shared.beginBackgroundTask(
                withName: "clear_application_state_after_interval",
                expirationHandler: taskExpirationHandler)

        let timerTickInterval = 0.5
        Timer.scheduledTimer(
            withTimeInterval: timerTickInterval,
            repeats: true
        ) { [weak self] timer in
            let cleanUpBackgroundTask = {
                timer.invalidate()
                endBackgroundTask()
            }

            guard let didEnterBackgroundTime = self?.didEnterBackgroundTime,
                timer.isValid
            else {
                // Cannot perform clear without `didEnterBackgroundTime or
                // with an invalid timer
                cleanUpBackgroundTask()
                return
            }
            let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
            let elapsedBackgroundTime = Date().timeIntervalSince(didEnterBackgroundTime)
            let totalAllottedBackgroundTime = backgroundTimeRemaining + elapsedBackgroundTime
            let minimumBackgroundClearInterval = StateClearer
                .minimumAcceptableBackgroundClearInterval
            guard totalAllottedBackgroundTime >= minimumBackgroundClearInterval else {
                // We aren't going to be able to wait in the background long enough
                // to perform the clear, so clean up the background task
                cleanUpBackgroundTask()
                return
            }

            // Perform the clear if:
            // - we're about to run out of background time, or
            // - we've reached the `desiredClearInterval`
            if backgroundTimeRemaining < timerTickInterval
                || elapsedBackgroundTime > StateClearer.desiredClearInterval
            {
                DebugLogger.log("Background cleared after \(elapsedBackgroundTime) seconds")
                self?.performStateClearRequests()
                cleanUpBackgroundTask()
            }
        }
    }
}
