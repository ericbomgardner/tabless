extension String {
    /// Returns whether the string looks like a web URL
    func isWebURL() -> Bool {
        return hasPrefix("http")
            || hasPrefix("www.")
            || contains(".com")
            || contains(".net")
            || contains(".org")
    }
}
