import Foundation
import SwiftUI

public enum ServiceState: String, Sendable {
    case running
    case stopped
    case starting
    case stopping
    case error
    case unknown

    public var title: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .starting: return "Starting…"
        case .stopping: return "Stopping…"
        case .error: return "Error"
        case .unknown: return "Unknown"
        }
    }

    public var color: Color {
        switch self {
        case .running: return .green
        case .stopped: return .secondary
        case .starting, .stopping: return .orange
        case .error: return .red
        case .unknown: return .gray
        }
    }

    public var isTransitioning: Bool {
        self == .starting || self == .stopping
    }
}

public struct ServiceInfo: Identifiable, Sendable {
    public let type: ServiceType
    public var state: ServiceState
    public var port: Int?
    public var pid: Int32?
    public var lastChecked: Date

    public var id: String { type.rawValue }

    public init(
        type: ServiceType,
        state: ServiceState = .unknown,
        port: Int? = nil,
        pid: Int32? = nil,
        lastChecked: Date = Date()
    ) {
        self.type = type
        self.state = state
        self.port = port ?? type.defaultPort
        self.pid = pid
        self.lastChecked = lastChecked
    }
}

public enum OverallStatus: String, Sendable {
    case allRunning
    case partiallyRunning
    case allStopped
    case unknown

    public var title: String {
        switch self {
        case .allRunning: return "All Services Running"
        case .partiallyRunning: return "Partially Running"
        case .allStopped: return "All Services Stopped"
        case .unknown: return "Checking Status…"
        }
    }

    public var subtitle: String {
        switch self {
        case .allRunning: return "Apache and MySQL are active."
        case .partiallyRunning: return "One of your services is stopped."
        case .allStopped: return "Apache and MySQL are stopped."
        case .unknown: return "Connecting to XAMPP daemon…"
        }
    }

    public var color: Color {
        switch self {
        case .allRunning: return .green
        case .partiallyRunning: return .orange
        case .allStopped: return .secondary
        case .unknown: return .gray
        }
    }

    public var systemImage: String {
        switch self {
        case .allRunning: return "checkmark.circle.fill"
        case .partiallyRunning: return "exclamationmark.triangle.fill"
        case .allStopped: return "stop.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}

