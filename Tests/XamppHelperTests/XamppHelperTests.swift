import Testing
import Foundation
@testable import XamppHelper

@Suite("Service Configuration Tests")
struct ServiceConfigurationTests {
    @Test("Service default ports and actions are correct")
    func serviceDefaults() {
        #expect(ServiceType.apache.defaultPort == 80)
        #expect(ServiceType.mysql.defaultPort == 3306)

        #expect(ServiceType.apache.startAction == "startapache")
        #expect(ServiceType.mysql.startAction == "startmysql")

        #expect(ServiceType.apache.stopAction == "stopapache")
        #expect(ServiceType.mysql.stopAction == "stopmysql")
    }

    @Test("Path configuration correctly resolves paths")
    func pathResolution() {
        #expect(PathConfig.xamppfilesPath == "/Applications/XAMPP/xamppfiles")
        #expect(PathConfig.xamppScript == "/Applications/XAMPP/xamppfiles/xampp")
        #expect(PathConfig.htdocsPath == "/Applications/XAMPP/xamppfiles/htdocs")
        #expect(PathConfig.apacheErrorLog == "/Applications/XAMPP/xamppfiles/logs/error_log")
        #expect(PathConfig.phpIniPath == "/Applications/XAMPP/xamppfiles/etc/php.ini")
        #expect(PathConfig.localhostURL.absoluteString == "http://localhost")
        #expect(PathConfig.phpMyAdminURL.absoluteString == "http://localhost/phpmyadmin")
    }

    @Test("Service info state transitions")
    func serviceStates() {
        var info = ServiceInfo(type: .apache, state: .stopped)
        #expect(!info.state.isTransitioning)

        info.state = .starting
        #expect(info.state.isTransitioning)

        info.state = .running
        #expect(!info.state.isTransitioning)
    }

    @Test("Log entry formatting")
    func logEntryFormatting() {
        let entry = LogEntry(level: .info, source: "App", message: "Test log message")
        #expect(!entry.formattedTimestamp.isEmpty)
        #expect(entry.source == "App")
        #expect(entry.message == "Test log message")
    }

    @Test("Command result formatting")
    func commandResultFormatting() {
        let res1 = CommandResult(exitCode: 0, stdout: "Success output", stderr: "")
        #expect(res1.isSuccess)
        #expect(res1.combinedOutput == "Success output")

        let res2 = CommandResult(exitCode: 1, stdout: "", stderr: "Error occurred")
        #expect(!res2.isSuccess)
        #expect(res2.combinedOutput == "Error occurred")
    }
}
