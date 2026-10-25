import Foundation

extension UserDefaults {
    private var preferredSearchEngineKey: String {
        // Matches key specified in Settings/Root.plist
        return "search_engine"
    }

    private var kagiTokenKey: String {
        // Matches key specified in Settings/Root.plist
        return "kagi_token"
    }

    var preferredSearchEngine: SearchEngine {
        if let preferenceValue = string(forKey: preferredSearchEngineKey) {
            let kagiToken = string(forKey: kagiTokenKey)
            return SearchEngine.fromPreferenceValue(preferenceValue, kagiToken: kagiToken)
        }
        return SearchEngine.default
    }

    /// Installs from before DuckDuckGo became the default keep Google unless they chose otherwise
    func pinInitialSearchEngine() {
        guard string(forKey: preferredSearchEngineKey) == nil else { return }
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let hasUsedWebKit = FileManager.default.fileExists(
            atPath: libraryURL.appendingPathComponent("WebKit").path)
        set(hasUsedWebKit ? "google" : "duckDuckGo", forKey: preferredSearchEngineKey)
    }
}
