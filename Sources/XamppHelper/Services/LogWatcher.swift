import Foundation

public enum LogWatcher {
    /// Read the tail (last N lines) of a given file path safely.
    public static func readTail(filePath: String, lineCount: Int = 100) -> [String] {
        guard FileManager.default.fileExists(atPath: filePath) else {
            return ["Log file does not exist: \(filePath)"]
        }

        guard FileManager.default.isReadableFile(atPath: filePath) else {
            return ["Log file exists but requires elevated permission to read: \(filePath)"]
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            // Only read the last ~200KB for performance
            let maxBytes = 200 * 1024
            let slice: Data
            if data.count > maxBytes {
                slice = data.suffix(maxBytes)
            } else {
                slice = data
            }

            guard let content = String(data: slice, encoding: .utf8) ?? String(data: slice, encoding: .isoLatin1) else {
                return ["Unable to decode log content."]
            }

            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            return Array(lines.suffix(lineCount))
        } catch {
            return ["Error reading log: \(error.localizedDescription)"]
        }
    }
}

