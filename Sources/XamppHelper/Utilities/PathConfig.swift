import Foundation

public struct PathConfig: Sendable {
    public static let defaultBasePath = "/Applications/XAMPP"
    public static let userDefaultsBasePathKey = "customXamppBasePath"

    public static var basePath: String {
        get {
            UserDefaults.standard.string(forKey: userDefaultsBasePathKey) ?? defaultBasePath
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsBasePathKey)
        }
    }

    public static var xamppfilesPath: String {
        (basePath as NSString).appendingPathComponent("xamppfiles")
    }

    public static var xamppScript: String {
        (xamppfilesPath as NSString).appendingPathComponent("xampp")
    }

    public static var htdocsPath: String {
        (xamppfilesPath as NSString).appendingPathComponent("htdocs")
    }

    public static var etcPath: String {
        (xamppfilesPath as NSString).appendingPathComponent("etc")
    }

    public static var logsPath: String {
        (xamppfilesPath as NSString).appendingPathComponent("logs")
    }

    public static var apacheErrorLog: String {
        (logsPath as NSString).appendingPathComponent("error_log")
    }

    public static var apacheAccessLog: String {
        (logsPath as NSString).appendingPathComponent("access_log")
    }

    public static var phpErrorLog: String {
        (logsPath as NSString).appendingPathComponent("php_error_log")
    }

    public static var phpIniPath: String {
        (etcPath as NSString).appendingPathComponent("php.ini")
    }

    public static var httpdConfPath: String {
        (etcPath as NSString).appendingPathComponent("httpd.conf")
    }

    public static var myCnfPath: String {
        (etcPath as NSString).appendingPathComponent("my.cnf")
    }

    public static var vhostsConfPath: String {
        ((etcPath as NSString).appendingPathComponent("extra") as NSString).appendingPathComponent("httpd-vhosts.conf")
    }

    public static var localhostURL: URL {
        URL(string: "http://localhost")!
    }

    public static var phpMyAdminURL: URL {
        URL(string: "http://localhost/phpmyadmin")!
    }

    public static func isValidInstallation(at path: String) -> Bool {
        let script = (path as NSString).appendingPathComponent("xamppfiles/xampp")
        return FileManager.default.isExecutableFile(atPath: script)
    }
}

