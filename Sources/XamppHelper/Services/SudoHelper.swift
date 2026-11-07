import Foundation

public enum SudoHelper {
    public static let sudoersFilePath = "/etc/sudoers.d/xampp-helper"

    /// Check whether passwordless sudo is configured and functioning.
    public static func isConfigured(xamppScript: String = "/Applications/XAMPP/xamppfiles/xampp") async -> Bool {
        // Test running statusraw with sudo -n
        let result = await CommandExecutor.run("/usr/bin/sudo", arguments: ["-n", xamppScript, "statusraw"])
        return result.isSuccess
    }

    /// Install the sudoers rule allowing passwordless execution of the XAMPP control script.
    public static func installRule(
        username: String = NSUserName(),
        xamppScript: String = "/Applications/XAMPP/xamppfiles/xampp"
    ) async -> CommandResult {
        let ruleContent = "\(username) ALL=(ALL) NOPASSWD: \(xamppScript)\n"
        let tempFile = "/tmp/xampp_sudoers_\(UUID().uuidString)"

        do {
            try ruleContent.write(toFile: tempFile, atomically: true, encoding: .utf8)
        } catch {
            return CommandResult(exitCode: 1, stdout: "", stderr: "Failed to write temporary rule: \(error.localizedDescription)")
        }

        let script = """
        do shell script "/usr/sbin/visudo -c -f '\(tempFile)' && cp '\(tempFile)' '\(sudoersFilePath)' && chown root:wheel '\(sudoersFilePath)' && chmod 0440 '\(sudoersFilePath)' && rm -f '\(tempFile)'" with administrator privileges
        """

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorDict: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    let outputDescriptor = appleScript.executeAndReturnError(&errorDict)
                    if let err = errorDict {
                        let errMsg = (err[NSAppleScript.errorMessage] as? String) ?? "Authorization failed"
                        // Clean up temp file
                        try? FileManager.default.removeItem(atPath: tempFile)
                        continuation.resume(returning: CommandResult(
                            exitCode: 1,
                            stdout: "",
                            stderr: errMsg
                        ))
                    } else {
                        let outputString = outputDescriptor.stringValue ?? ""
                        try? FileManager.default.removeItem(atPath: tempFile)
                        continuation.resume(returning: CommandResult(
                            exitCode: 0,
                            stdout: outputString.isEmpty ? "Passwordless sudo successfully configured!" : outputString,
                            stderr: ""
                        ))
                    }
                } else {
                    try? FileManager.default.removeItem(atPath: tempFile)
                    continuation.resume(returning: CommandResult(
                        exitCode: 1,
                        stdout: "",
                        stderr: "Could not create AppleScript"
                    ))
                }
            }
        }
    }

    /// Remove the sudoers rule.
    public static func removeRule() async -> CommandResult {
        let script = """
        do shell script "rm -f '\(sudoersFilePath)'" with administrator privileges
        """

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorDict: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    _ = appleScript.executeAndReturnError(&errorDict)
                    if let err = errorDict {
                        let errMsg = (err[NSAppleScript.errorMessage] as? String) ?? "Failed to remove sudoers file"
                        continuation.resume(returning: CommandResult(
                            exitCode: 1,
                            stdout: "",
                            stderr: errMsg
                        ))
                    } else {
                        continuation.resume(returning: CommandResult(
                            exitCode: 0,
                            stdout: "Passwordless sudo rule removed.",
                            stderr: ""
                        ))
                    }
                } else {
                    continuation.resume(returning: CommandResult(
                        exitCode: 1,
                        stdout: "",
                        stderr: "Could not create AppleScript"
                    ))
                }
            }
        }
    }
}
