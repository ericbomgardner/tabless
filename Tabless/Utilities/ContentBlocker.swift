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

    /// Compiled lists are cached by identifier, so tie them to the build that bundled the JSON
    private static let appVersion: String = {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "\(version)-\(build)"
    }()

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

        let store = await WKContentRuleListStore.default()!
        let identifiers = blocklistNames.map { "\($0)-\(Self.appVersion)" }

        for (blocklist, identifier) in zip(blocklistNames, identifiers) {
            if let existingList = try? await store.contentRuleList(forIdentifier: identifier) {
                contentRuleLists.append(existingList)
                continue
            }

            do {
                let blocklistPath = blocklistDirectory.appendingPathComponent(blocklist)
                let blocklistJson = try String(
                    contentsOfFile: blocklistPath.relativePath, encoding: String.Encoding.utf8)
                let contentRuleList = try await store.compileContentRuleList(
                    forIdentifier: identifier, encodedContentRuleList: blocklistJson)!
                contentRuleLists.append(contentRuleList)
            } catch {
                DebugLogger.log("Failed to load blocklist: \(blocklist)")
            }
        }

        // WebKit keeps its own lists in this store, so only touch ones made from our JSON files
        let staleIdentifiers = Set(await store.availableIdentifiers() ?? [])
            .filter { $0.contains(".json") }
            .subtracting(identifiers)
        for identifier in staleIdentifiers {
            try? await store.removeContentRuleList(forIdentifier: identifier)
        }

        return contentRuleLists
    }
}
