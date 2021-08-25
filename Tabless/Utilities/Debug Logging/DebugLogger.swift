import Foundation

struct DebugLogFile {
    static let filename = "tabless_debug_log.txt"

    static var fileUrl: URL {
        let userHomeDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return userHomeDirectory.appendingPathComponent(filename)
    }
}

/// Writes debug logs to file in debug builds
struct DebugLogWriter: TextOutputStream {
    static var shared = DebugLogWriter()

    mutating func write(_ string: String) {
        guard string.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            return
        }
        let stringData = "\(Date()): \(string)\n\n".data(using: .utf8)!
        let logFileUrl = DebugLogFile.fileUrl
        if let fileHandle = try? FileHandle(forWritingTo: logFileUrl) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(stringData)
            fileHandle.closeFile()
        } else {
            try! stringData.write(to: logFileUrl)
        }
    }
}

/// Logs in debug builds
struct DebugLogger {
    /// Log `string`
    static func log(_ string: String) {
        #if DEBUG
        print(string, to: &DebugLogWriter.shared)
        #endif
        print(string)
    }

    /// Read all logs
    static func allLogs() -> String? {
        return try? String(contentsOf: DebugLogFile.fileUrl)
    }

    /// Clear all logs
    static func clearAllLogs() {
        try? FileManager.default.removeItem(at: DebugLogFile.fileUrl)
    }
}
