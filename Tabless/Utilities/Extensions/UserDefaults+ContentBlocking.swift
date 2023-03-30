import Foundation

extension UserDefaults {
    private var contentBlockingKey: String {
        // Matches key specified in Settings/Root.plist
        return "content_blocking"
    }

    var isContentBlockingEnabled: Bool {
        get {
            return bool(forKey: contentBlockingKey)
        }
        set {
            setValue(newValue, forKey: contentBlockingKey)
        }
    }
}
