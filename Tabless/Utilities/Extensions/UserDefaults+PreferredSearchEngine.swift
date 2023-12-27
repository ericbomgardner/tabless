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
}
