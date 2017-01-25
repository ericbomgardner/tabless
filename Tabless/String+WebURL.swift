extension String {
    func isWebURL() -> Bool {
        return hasPrefix("www.") || contains(".com") || contains(".net") || contains(".org")
    }
}
