import Foundation

extension FileManager {

    /// Removes the contents of a directory specified by `url`
    public func removeContents(of url: URL) throws {
        let subdirectoryUrls =
            try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles)
        for subdirectoryUrl in subdirectoryUrls {
            try FileManager.default.removeItem(at: subdirectoryUrl)
        }
    }
}
