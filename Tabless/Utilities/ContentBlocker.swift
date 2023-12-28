import WebKit

class ContentBlocker {
    private var isContentBlockingEnabled = UserDefaults.standard.contentBlocking {
        didSet {
            updateBlocklists()
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

    func setUpBlocklists() {
        guard isContentBlockingEnabled else {
            return
        }

        DebugLogger.log("Setting up content blocking")
        Task {
            let blocklists = await getBlocklists()
            await MainActor.run {
                for blocklist in blocklists {
                    userContentController.add(blocklist)
                }
            }
            DebugLogger.log("Content blocking setup complete")
        }
    }

    private func updateBlocklists() {
        if isContentBlockingEnabled {
            setUpBlocklists()
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

    private struct Blocklist {
        let identifier: String
        let filename: String

        init(_ name: String) {
            self.identifier = name
            self.filename = name
        }
    }

    private enum BlocklistError: Error {
        case blocklistMissing
    }

    private func getBlocklists() async -> [WKContentRuleList] {
        let allBlocklists = [
            Blocklist("advertising"),
            Blocklist("analytics"),
            Blocklist("content"),
            Blocklist("social"),
        ]

        var contentRuleLists = [WKContentRuleList]()
        for blocklist in allBlocklists {
            let blocklistIdentifier = blocklist.identifier

            if let existingList = try? await WKContentRuleListStore.default().contentRuleList(forIdentifier: blocklistIdentifier) {
                contentRuleLists.append(existingList)
                continue
            }

            do {
                guard let blocklistPath = Bundle.main.path(forResource: blocklist.filename, ofType: "json", inDirectory: "Blocklists") else {
                    throw BlocklistError.blocklistMissing
                }
                let blocklistJson = try String(contentsOfFile: blocklistPath, encoding: String.Encoding.utf8)
                let contentRuleList = try await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: blocklistIdentifier, encodedContentRuleList: blocklistJson)!
                contentRuleLists.append(contentRuleList)
            } catch {
                DebugLogger.log("Failed to load blocklist: \(blocklistIdentifier)")
            }
        }
        return contentRuleLists
    }
}
