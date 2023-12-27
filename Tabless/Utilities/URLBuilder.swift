import Foundation

struct URLBuilder {
    private let searchEngine: SearchEngine

    init(searchEngine: SearchEngine) {
        self.searchEngine = searchEngine
    }

    /// If text looks like a URL, creates that URL
    /// Otherwise, treats it like a search query and returns a search URL
    func createURL(_ text: String) -> URL? {
        if shouldTreatAsWebURL(text) {
            return createWebURL(text)
        } else {
            return createSearchURL(text)
        }
    }

    // MARK: Private

    /// Whether input text should be treated as a web URL
    private func shouldTreatAsWebURL(_ text: String) -> Bool {
        return canTreatAsWebURL(text) && text.contains(".")
    }

    private func createWebURL(_ text: String) -> URL? {
        return asWebURL(text)
    }

    /// Whether a valid web URL can be created from the string
    private func canTreatAsWebURL(_ text: String) -> Bool {
        return asWebURL(text) != nil
    }

    /// Representation of the string as a web URL
    private func asWebURL(_ text: String) -> URL? {
        let urlString: String
        if !text.hasPrefix("http") {
            urlString = "https://\(text)"
        } else {
            urlString = text
        }
        return URL(string: urlString)
    }

    private func createSearchURL(_ text: String) -> URL? {
        guard let searchQuery = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            return nil
        }
        return searchEngine.url(query: searchQuery)
    }
}
