import UIKit

protocol StateResettable: class {
    func reset()
}

private class StateClearingRequest {
    weak var stateResettable: StateResettable? = nil
    let retentionLength: TimeInterval

    init(stateResettable: StateResettable?,
         retentionLength: TimeInterval) {
        self.stateResettable = stateResettable
        self.retentionLength = retentionLength
    }
}

private struct StateClearingOperation {
    let id: String
    let backgroundTaskIdentifier: UIBackgroundTaskIdentifier
    let timer: Timer
}

class StateClearer {
    private weak var application: UIApplication?

    private var requests = [StateClearingRequest]()
    private var operations = [StateClearingOperation]()

    init(application: UIApplication) {
        self.application = application
    }

    func addStateClearRequest(for stateResettable: StateResettable,
                              after retentionLength: TimeInterval) {
        let request = StateClearingRequest(stateResettable: stateResettable,
                                           retentionLength: retentionLength)
        requests.append(request)
    }

    func beginClearTimer() {
        for request in requests {
            guard let application = self.application else {
                return
            }

            let operationId = UUID().uuidString
            let operationIdMatches: (StateClearingOperation) -> Bool = { operation -> Bool in
                operation.id == operationId
            }
            let completeOperation = { [weak self] in
                guard let operations = self?.operations,
                    let operationIndex = operations.firstIndex(where: operationIdMatches) else
                {
                    return
                }
                application.endBackgroundTask(operations[operationIndex].backgroundTaskIdentifier)
                self?.operations.remove(at: operationIndex)
            }

            let cleanupBackgroundTask = application.beginBackgroundTask(withName: "clear_data_after_timer_expires",
                                                                        expirationHandler: completeOperation)

            let timer = Timer.scheduledTimer(withTimeInterval: request.retentionLength,
                                             repeats: false) { timer in
                if timer.isValid {
                    request.stateResettable?.reset()
                }
                completeOperation()
            }

            let operation = StateClearingOperation(id: operationId,
                                                   backgroundTaskIdentifier: cleanupBackgroundTask,
                                                   timer: timer)
            operations.append(operation)
        }
    }

    func cancelPendingStateClears() {
        for operation in operations {
            operation.timer.invalidate()
            application?.endBackgroundTask(operation.backgroundTaskIdentifier)
        }
        operations.removeAll()
    }
}
