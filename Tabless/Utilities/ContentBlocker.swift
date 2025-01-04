import WebKit

class ContentBlocker {
    private var isContentBlockingEnabled = UserDefaults.standard.contentBlocking {
        didSet {
            updateBlocklists()
        }
    }

    private let userContentController: WKUserContentController

    private var observer: NSKeyValueObservation?

    private var cachedBlocklistNames: [String]?

    init(userContentController: WKUserContentController) {
        self.userContentController = userContentController

        observer = UserDefaults.standard.observe(
            \.contentBlocking, options: [.new],
            changeHandler: { [weak self] (defaults, change) in
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

    private enum BlocklistError: Error {
        case blocklistMissing
    }

    private func getBlocklists() async -> [WKContentRuleList] {
        var contentRuleLists = [WKContentRuleList]()

        let blocklistDirectory = Bundle.main.resourceURL!.appendingPathComponent(
            "Blocklists", isDirectory: true)

        let blocklistNames: [String]
        if let cachedBlocklistNames {
            blocklistNames = cachedBlocklistNames
        } else {
            if let filenames = try? FileManager.default.contentsOfDirectory(
                atPath: blocklistDirectory.relativePath)
            {
                if filenames.isEmpty {
                    assertionFailure("Could not find blocklists in blocklist directory")
                }
                blocklistNames = filenames.filter { name in
                    // Disconnect's "content" list is their unblocked trackers
                    !name.contains("content")
                }
            } else {
                assertionFailure("Could not find blocklist directory")
                blocklistNames = []
            }
            cachedBlocklistNames = blocklistNames
        }

        for blocklist in blocklistNames {
            if let existingList = try? await WKContentRuleListStore.default().contentRuleList(
                forIdentifier: blocklist)
            {
                contentRuleLists.append(existingList)
                continue
            }

            do {
                let blocklistPath = blocklistDirectory.appendingPathComponent(blocklist)
                let blocklistJson = try String(
                    contentsOfFile: blocklistPath.relativePath, encoding: String.Encoding.utf8)
                let contentRuleList = try await WKContentRuleListStore.default()
                    .compileContentRuleList(
                        forIdentifier: blocklist, encodedContentRuleList: blocklistJson)!
                contentRuleLists.append(contentRuleList)
            } catch {
                DebugLogger.log("Failed to load blocklist: \(blocklist)")
            }
        }
        return contentRuleLists
    }
}
