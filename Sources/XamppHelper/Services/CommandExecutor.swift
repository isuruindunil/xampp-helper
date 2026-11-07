import Foundation

public struct CommandResult: Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public var isSuccess: Bool {
        exitCode == 0
    }

    public var combinedOutput: String {
        let out = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let err = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if out.isEmpty { return err }
        if err.isEmpty { return out }
        return "\(out)\n\(err)"
    }
}

public enum CommandExecutor {
    /// Execute a standard shell command as the current user.
    public static func run(
        _ executable: String,
        arguments: [String] = [],
        environment: [String: String]? = nil
    ) async -> CommandResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments

                var env = ProcessInfo.processInfo.environment
                if let customEnv = environment {
                    env.merge(customEnv) { _, new in new }
                }
                process.environment = env

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                    let stdout = String(data: outData, encoding: .utf8) ?? ""
                    let stderr = String(data: errData, encoding: .utf8) ?? ""

                    continuation.resume(returning: CommandResult(
                        exitCode: process.terminationStatus,
                        stdout: stdout,
                        stderr: stderr
                    ))
                } catch {
                    continuation.resume(returning: CommandResult(
                        exitCode: -1,
                        stdout: "",
                        stderr: error.localizedDescription
                    ))
                }
            }
        }
    }

    /// Check if passwordless sudo is currently working for a specific command.
    public static func checkPasswordlessSudo(command: String) async -> Bool {
        let result = await run("/usr/bin/sudo", arguments: ["-n", command, "statusraw"])
        return result.isSuccess
    }

    /// Run a command with elevated privileges.
    /// If passwordless sudo is available, it uses `sudo -n`.
    /// Otherwise, it prompts the user using AppleScript with administrator privileges.
    public static func runElevated(
        command: String,
        arguments: [String] = []
    ) async -> CommandResult {
        let fullArgs = [command] + arguments

        // 1. Try passwordless sudo first
        let sudoCheck = await run("/usr/bin/sudo", arguments: ["-n"] + fullArgs)
        if sudoCheck.isSuccess {
            return sudoCheck
        }

        // 2. If sudo -n failed because of password requirement, use AppleScript
        let escapedArgs = fullArgs.map { "\"\($0.replacingOccurrences(of: "\"", with: "\\\""))\"" }.joined(separator: " ")
        let script = "do shell script \"\(escapedArgs)\" with administrator privileges"

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorDict: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    let outputDescriptor = appleScript.executeAndReturnError(&errorDict)
                    if let err = errorDict {
                        let errMsg = (err[NSAppleScript.errorMessage] as? String) ?? "Authorization failed"
                        continuation.resume(returning: CommandResult(
                            exitCode: 1,
                            stdout: "",
                            stderr: errMsg
                        ))
                    } else {
                        let outputString = outputDescriptor.stringValue ?? ""
                        continuation.resume(returning: CommandResult(
                            exitCode: 0,
                            stdout: outputString,
                            stderr: ""
                        ))
                    }
                } else {
                    continuation.resume(returning: CommandResult(
                        exitCode: 1,
                        stdout: "",
                        stderr: "Could not create AppleScript instance"
                    ))
                }
            }
        }
    }
}

