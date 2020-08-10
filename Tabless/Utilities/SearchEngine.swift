import Foundation

enum SearchEngine: String {
    case google
    case duckDuckGo

    var baseURL: String {
        switch self {
        case .google:
            return "https://www.google.com/search?q="
        case .duckDuckGo:
            return "https://duckduckgo.com/?q="
        }
    }

    static var `default`: SearchEngine {
        return .google
    }
}
