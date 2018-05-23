import Foundation

struct URLBuilder {
    private static let searchURLBase = "https://www.google.com/search?q="

    /// If text looks like a URL, creates that URL
    /// Otherwise, treats it like a search query
    static func createURL(_ text: String) -> URL? {
        let urlString: String
        if text.isWebURL() {
            if !text.hasPrefix("http") {
                urlString = "https://\(text)"
            } else {
                urlString = text
            }
        } else if let searchQuery = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            urlString = "\(searchURLBase)\(searchQuery)"
        } else {
            return nil
        }
        return URL(string: urlString)
    }
}

private extension String {
    /// Returns whether the string looks like a web URL
    func isWebURL() -> Bool {
        return hasPrefix("http")
            || hasPrefix("www.")
            || contains(".com")
            || contains(".net")
            || contains(".org")
    }
}
