extension String {
    /// Returns whether the string looks like a web URL
    /// TODO(#2): Better detect URLs
    func isWebURL() -> Bool {
        return hasPrefix("http")
            || hasPrefix("www.")
            || contains(".com")
            || contains(".net")
            || contains(".org")
    }
}
