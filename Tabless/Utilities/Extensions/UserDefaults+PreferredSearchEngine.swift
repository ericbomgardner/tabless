import Foundation

extension UserDefaults {
    private var preferredSearchEngineKey: String {
        // Matches key specified in Settings/Root.plist
        return "search_engine"
    }

    var preferredSearchEngine: SearchEngine {
        get {
            if let preferenceValue = string(forKey: preferredSearchEngineKey),
                let searchEnginePreference = SearchEngine(rawValue: preferenceValue)
            {
                return searchEnginePreference
            }
            return SearchEngine.default
        }
        set {
            setValue(newValue.rawValue, forKey: preferredSearchEngineKey)
        }
    }
}
