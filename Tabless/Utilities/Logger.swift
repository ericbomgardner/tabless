import Foundation

/// Logs to file specified by `filename`
struct Logger: TextOutputStream {
    static var shared = Logger()

    private static let filename = "log.txt"

    private var logFileUrl: URL {
        let userHomeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return userHomeDirectory.appendingPathComponent(Logger.filename)
    }

    mutating func write(_ string: String) {
        guard string.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return
        }
        print(string)
        let stringData = "\(Date()): \(string)\n\n".data(using: .utf8)!
        let logFileUrl = self.logFileUrl
        if let fileHandle = try? FileHandle(forWritingTo: logFileUrl) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(stringData)
            fileHandle.closeFile()
        } else {
            try! stringData.write(to: logFileUrl)
        }
    }

    func read() -> String? {
        return try? String(contentsOf: logFileUrl)
    }

    func clear() {
        try? FileManager.default.removeItem(at: logFileUrl)
    }
}
