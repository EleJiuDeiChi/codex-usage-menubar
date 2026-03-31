import Foundation

struct CommandInvocation: Sendable, Equatable {
    let executable: String
    let arguments: [String]
}

struct CommandOutput: Sendable, Equatable {
    let standardOutput: Data
    let standardError: Data
    let exitCode: Int32
}

protocol CommandRunning: Sendable {
    func run(_ invocation: CommandInvocation) async throws -> CommandOutput
}

enum CommandRunnerError: Error, Equatable {
    case executionFailed(String)
    case nonZeroExit(code: Int32, message: String)
}

struct CodexUsageService: Sendable {
    let commandRunner: CommandRunning
    let executableLocator: CodexExecutableLocator
    let nodeLocator: NodeExecutableLocator
    let fileReader: @Sendable (String) throws -> String

    init(
        commandRunner: CommandRunning = LiveCommandRunner(),
        executableLocator: CodexExecutableLocator = CodexExecutableLocator(),
        nodeLocator: NodeExecutableLocator = NodeExecutableLocator(),
        fileReader: @escaping @Sendable (String) throws -> String = { try String(contentsOfFile: $0, encoding: .utf8) }
    ) {
        self.commandRunner = commandRunner
        self.executableLocator = executableLocator
        self.nodeLocator = nodeLocator
        self.fileReader = fileReader
    }

    func fetchDailyReport(since: String, until: String) async throws -> CodexUsageReport {
        guard let executable = executableLocator.locate() else {
            throw CommandRunnerError.executionFailed("Could not find ccusage-codex. Install it first or add it to PATH.")
        }

        let invocation = try makeInvocation(
            executable: executable,
            arguments: ["daily", "--since", since, "--until", until, "--json"]
        )

        let output = try await commandRunner.run(
            invocation
        )

        guard output.exitCode == 0 else {
            let message = String(data: output.standardError, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw CommandRunnerError.nonZeroExit(code: output.exitCode, message: message ?? "Command failed")
        }

        return try UsageParser.parseDailyReport(from: output.standardOutput)
    }

    private func makeInvocation(executable: String, arguments: [String]) throws -> CommandInvocation {
        guard let header = try? fileReader(executable).split(separator: "\n", maxSplits: 1).first.map(String.init) else {
            return CommandInvocation(executable: executable, arguments: arguments)
        }

        if header.contains("/usr/bin/env node") || header.contains("/bin/env node") {
            guard let node = nodeLocator.locate() else {
                throw CommandRunnerError.executionFailed("Found ccusage-codex, but Node.js is not available to launch it.")
            }

            return CommandInvocation(executable: node, arguments: [executable] + arguments)
        }

        return CommandInvocation(executable: executable, arguments: arguments)
    }
}

struct LiveCommandRunner: CommandRunning {
    func run(_ invocation: CommandInvocation) async throws -> CommandOutput {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [invocation.executable] + invocation.arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { process in
                let output = CommandOutput(
                    standardOutput: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
                    standardError: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
                    exitCode: process.terminationStatus
                )
                continuation.resume(returning: output)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: CommandRunnerError.executionFailed(error.localizedDescription))
            }
        }
    }
}

struct CodexExecutableLocator: Sendable {
    var environment: [String: String] = ProcessInfo.processInfo.environment
    var fileExists: @Sendable (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    var nvmVersionsProvider: @Sendable () -> [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let base = "\(home)/.nvm/versions/node"
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: base) else {
            return []
        }

        return entries
            .sorted()
            .map { "\(base)/\($0)/bin/ccusage-codex" }
    }

    func locate() -> String? {
        for candidate in pathCandidates + homebrewCandidates + nvmVersionsProvider().reversed() {
            if fileExists(candidate) {
                return candidate
            }
        }

        return nil
    }

    private var pathCandidates: [String] {
        let rawPath = environment["PATH"] ?? ""
        return rawPath
            .split(separator: ":")
            .map { "\($0)/ccusage-codex" }
    }

    private var homebrewCandidates: [String] {
        [
            "/opt/homebrew/bin/ccusage-codex",
            "/usr/local/bin/ccusage-codex"
        ]
    }
}

struct NodeExecutableLocator: Sendable {
    var environment: [String: String] = ProcessInfo.processInfo.environment
    var fileExists: @Sendable (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    var nvmVersionsProvider: @Sendable () -> [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let base = "\(home)/.nvm/versions/node"
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: base) else {
            return []
        }

        return entries
            .sorted()
            .map { "\(base)/\($0)/bin/node" }
    }

    func locate() -> String? {
        for candidate in pathCandidates + homebrewCandidates + nvmVersionsProvider().reversed() {
            if fileExists(candidate) {
                return candidate
            }
        }

        return nil
    }

    private var pathCandidates: [String] {
        let rawPath = environment["PATH"] ?? ""
        return rawPath
            .split(separator: ":")
            .map { "\($0)/node" }
    }

    private var homebrewCandidates: [String] {
        [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node"
        ]
    }
}
