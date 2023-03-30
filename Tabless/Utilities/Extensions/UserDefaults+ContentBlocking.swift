import Foundation

extension UserDefaults {
    // Matches key specified in Settings/Root.plist
    @objc dynamic var contentBlocking: Bool {
        return object(forKey: #function) as? Bool ?? true
    }
}
