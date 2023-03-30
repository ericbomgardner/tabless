import WebKit

class ContentBlocker {
    private var isContentBlockingEnabled = UserDefaults.standard.contentBlocking {
        didSet {
            updateBlocklist()
        }
    }

    private let userContentController: WKUserContentController

    private var observer: NSKeyValueObservation?

    init(userContentController: WKUserContentController) {
        self.userContentController = userContentController

        observer = UserDefaults.standard.observe(\.contentBlocking, options: [.new], changeHandler: { [weak self] (defaults, change) in
            if let newValue = change.newValue {
                self?.isContentBlockingEnabled = newValue
            }
        })
    }

    deinit {
        observer?.invalidate()
    }

    func setUpBlocklist() {
        guard isContentBlockingEnabled else {
            return
        }

        DebugLogger.log("Setting up content blocking")
        Task {
            let blocklist = await getBlocklist()
            await MainActor.run {
                userContentController.add(blocklist)
            }
            DebugLogger.log("Content blocking setup complete")
        }
    }

    private func updateBlocklist() {
        if isContentBlockingEnabled {
            setUpBlocklist()
        } else {
            DebugLogger.log("Disabling content blocking")
            Task {
                await MainActor.run {
                    userContentController.removeAllContentRuleLists()
                }
                DebugLogger.log("Content blocking disabling complete")
            }
        }
    }

    private func getBlocklist() async -> WKContentRuleList {
        let blocklistIdentifier = "blocklist"

        if let existingList = try? await WKContentRuleListStore.default().contentRuleList(forIdentifier: blocklistIdentifier) {
            return existingList
        }

        let blocklistPath = Bundle.main.path(forResource: "blocklist", ofType: "json")!
        let blocklistJson = try! String(contentsOfFile: blocklistPath, encoding: String.Encoding.utf8)
        return try! await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: blocklistIdentifier, encodedContentRuleList: blocklistJson)!
    }
}
