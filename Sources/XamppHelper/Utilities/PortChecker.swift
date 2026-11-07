import Foundation
import Darwin

public struct PortStatus: Identifiable, Sendable {
    public let port: Int
    public let serviceName: String
    public let isListening: Bool
    public let isOccupiedByXampp: Bool

    public var id: Int { port }

    public var isConflict: Bool {
        isListening && !isOccupiedByXampp
    }
}

public enum PortChecker: Sendable {
    /// Check whether a TCP port on localhost (127.0.0.1) is accepting connections.
    public static func isPortOpen(port: Int) -> Bool {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        var timeout = timeval(tv_sec: 0, tv_usec: 300_000) // 300ms timeout
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(port).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                Darwin.connect(sock, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return result == 0
    }

    /// Check standard XAMPP ports (80, 443, 3306) for availability and potential conflicts.
    public static func checkStandardPorts(apacheRunning: Bool, mysqlRunning: Bool) async -> [PortStatus] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let open80 = isPortOpen(port: 80)
                let open443 = isPortOpen(port: 443)
                let open3306 = isPortOpen(port: 3306)

                let statuses = [
                    PortStatus(port: 80, serviceName: "Apache HTTP", isListening: open80, isOccupiedByXampp: apacheRunning),
                    PortStatus(port: 443, serviceName: "Apache HTTPS (SSL)", isListening: open443, isOccupiedByXampp: apacheRunning),
                    PortStatus(port: 3306, serviceName: "MySQL / MariaDB", isListening: open3306, isOccupiedByXampp: mysqlRunning)
                ]
                continuation.resume(returning: statuses)
            }
        }
    }
}
