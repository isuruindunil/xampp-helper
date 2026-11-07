import Foundation
import SwiftUI

public enum LogLevel: String, Sendable {
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARN"
    case error = "ERROR"

    public var color: Color {
        switch self {
        case .info: return .primary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

public struct LogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let level: LogLevel
    public let source: String
    public let message: String

    public init(timestamp: Date = Date(), level: LogLevel = .info, source: String = "XAMPP", message: String) {
        self.timestamp = timestamp
        self.level = level
        self.source = source
        self.message = message
    }

    public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

