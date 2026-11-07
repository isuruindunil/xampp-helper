import Foundation
import SwiftUI

public enum ServiceType: String, CaseIterable, Identifiable, Sendable {
    case apache = "Apache"
    case mysql = "MySQL"
    case proftpd = "ProFTPD"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .apache: return "Apache Web Server"
        case .mysql: return "MySQL Database"
        case .proftpd: return "ProFTPD FTP Server"
        }
    }

    public var defaultPort: Int {
        switch self {
        case .apache: return 80
        case .mysql: return 3306
        case .proftpd: return 21
        }
    }

    public var systemImage: String {
        switch self {
        case .apache: return "globe"
        case .mysql: return "cylinder.split.1x2"
        case .proftpd: return "folder.badge.gearshape"
        }
    }

    public var processName: String {
        switch self {
        case .apache: return "httpd"
        case .mysql: return "mysqld"
        case .proftpd: return "proftpd"
        }
    }

    public var startAction: String {
        switch self {
        case .apache: return "startapache"
        case .mysql: return "startmysql"
        case .proftpd: return "startftp"
        }
    }

    public var stopAction: String {
        switch self {
        case .apache: return "stopapache"
        case .mysql: return "stopmysql"
        case .proftpd: return "stopftp"
        }
    }

    public var reloadAction: String {
        switch self {
        case .apache: return "reloadapache"
        case .mysql: return "reloadmysql"
        case .proftpd: return "reloadftp"
        }
    }

    public var configPath: String {
        switch self {
        case .apache: return "/Applications/XAMPP/xamppfiles/etc/httpd.conf"
        case .mysql: return "/Applications/XAMPP/xamppfiles/etc/my.cnf"
        case .proftpd: return "/Applications/XAMPP/xamppfiles/etc/proftpd.conf"
        }
    }
}

