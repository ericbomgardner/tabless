import Foundation

enum SearchEngine {
    case google
    case duckDuckGo
    case kagi(token: String)

    func url(query: String) -> URL {
        let urlString: String
        switch self {
        case .google:
            urlString = "https://www.google.com/search?q=\(query)"
        case .duckDuckGo:
            urlString = "https://duckduckgo.com/?q=\(query)"
        case .kagi(let token):
            urlString = "https://kagi.com/search?token=\(token)&q=\(query)"
        }
        return URL(string: urlString)!
    }

    static var `default`: SearchEngine {
        return .google
    }

    /// `preferenceValue` matches key specified in Settings/Root.plist
    static func fromPreferenceValue(_ preferenceValue: String, kagiToken: String?) -> Self {
        switch preferenceValue {
        case "google":
            return .google
        case "duckDuckGo":
            return .duckDuckGo
        case "kagi":
            return .kagi(token: kagiToken ?? "")
        default:
            return .google
        }
    }
}
