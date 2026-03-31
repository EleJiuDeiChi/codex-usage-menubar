import Foundation
import Testing
@testable import CodexMenuBarApp

@Test
func serviceBuildsTodayCommandAndParsesResponse() async throws {
    let runner = MockCommandRunner()
    runner.result = .success(.init(
        standardOutput: Data(singleDayJSON.utf8),
        standardError: Data(),
        exitCode: 0
    ))
    let service = CodexUsageService(
        commandRunner: runner,
        executableLocator: CodexExecutableLocator(
            environment: [:],
            fileExists: { $0 == "/mock/bin/ccusage-codex" },
            nvmVersionsProvider: { ["/mock/bin/ccusage-codex"] }
        ),
        nodeLocator: NodeExecutableLocator(
            environment: [:],
            fileExists: { $0 == "/mock/bin/node" },
            nvmVersionsProvider: { ["/mock/bin/node"] }
        ),
        fileReader: { path in
            if path == "/mock/bin/ccusage-codex" {
                return "#!/usr/bin/env node\nconsole.log('hi')\n"
            }
            throw NSError(domain: "test", code: 1)
        }
    )

    let report = try await service.fetchDailyReport(
        since: "2026-03-31",
        until: "2026-03-31"
    )

    #expect(runner.invocations == [
        CommandInvocation(
            executable: "/mock/bin/node",
            arguments: ["/mock/bin/ccusage-codex", "daily", "--since", "2026-03-31", "--until", "2026-03-31", "--json"]
        )
    ])
    #expect(report.days.count == 1)
    #expect(report.totalCostUSD == 127.915121)
}

@Test
func viewModelRefreshLoadsTodayAndWeeklyData() async throws {
    let runner = MockCommandRunner()
    runner.results = [
        Result.success(CommandOutput(standardOutput: Data(singleDayJSON.utf8), standardError: Data(), exitCode: 0)),
        Result.success(CommandOutput(standardOutput: Data(weeklyJSON.utf8), standardError: Data(), exitCode: 0))
    ]
    let locator = CodexExecutableLocator(
        environment: [:],
        fileExists: { $0 == "/mock/bin/ccusage-codex" },
        nvmVersionsProvider: { ["/mock/bin/ccusage-codex"] }
    )
    let nodeLocator = NodeExecutableLocator(
        environment: [:],
        fileExists: { $0 == "/mock/bin/node" },
        nvmVersionsProvider: { ["/mock/bin/node"] }
    )
    let service = CodexUsageService(
        commandRunner: runner,
        executableLocator: locator,
        nodeLocator: nodeLocator,
        fileReader: { path in
            if path == "/mock/bin/ccusage-codex" {
                return "#!/usr/bin/env node\nconsole.log('hi')\n"
            }
            throw NSError(domain: "test", code: 1)
        }
    )
    let projectUsageService = ProjectUsageService(
        sessionLogStore: MockProjectLogStore(),
        pricingService: ModelPricingService(
            client: MockProjectPricingClient(result: .success(Data(projectPricingJSON.utf8))),
            featuredModels: ["gpt-5.4"]
        )
    )
    let viewModel = MenuBarViewModel(
        service: service,
        projectUsageService: projectUsageService
    )

    await viewModel.refresh(now: fixedNow)

    let snapshot = await viewModel.snapshot
    #expect(snapshot.menuBarTitle == "Codex $127.92")
    #expect(snapshot.todayCostText == "$127.92")
    #expect(snapshot.inputTokensText == "281.5M")
    #expect(snapshot.outputTokensText == "1.8M")
    #expect(snapshot.weeklyRows.count == 4)
    #expect(snapshot.projectRows.count == 1)
    #expect(snapshot.projectRows[0].displayName == "codex检测")
    #expect(snapshot.errorMessage == nil)
}

@Test
func viewModelSurfacesCommandFailure() async throws {
    let runner = MockCommandRunner()
    runner.result = .failure(CommandRunnerError.executionFailed("missing binary"))
    let locator = CodexExecutableLocator(
        environment: [:],
        fileExists: { _ in false },
        nvmVersionsProvider: { [] }
    )
    let service = CodexUsageService(
        commandRunner: runner,
        executableLocator: locator,
        nodeLocator: NodeExecutableLocator(
            environment: [:],
            fileExists: { _ in false },
            nvmVersionsProvider: { [] }
        )
    )
    let viewModel = MenuBarViewModel(service: service)

    await viewModel.refresh(now: fixedNow)

    let snapshot = await viewModel.snapshot
    #expect(snapshot.menuBarTitle == "Codex --")
    #expect(snapshot.errorMessage == "Could not find ccusage-codex. Install it first or add it to PATH.")
}

private let fixedNow = ISO8601DateFormatter().date(from: "2026-03-31T10:00:00Z")!

private final class MockCommandRunner: CommandRunning, @unchecked Sendable {
    var invocations: [CommandInvocation] = []
    var result: Result<CommandOutput, Error>?
    var results: [Result<CommandOutput, Error>] = []

    func run(_ invocation: CommandInvocation) async throws -> CommandOutput {
        invocations.append(invocation)

        if !results.isEmpty {
            return try results.removeFirst().get()
        }

        guard let result else {
            fatalError("Missing stubbed result")
        }

        return try result.get()
    }
}

private struct MockProjectLogStore: SessionLogStoring {
    func listSessionFiles(for dayPath: String) throws -> [SessionLogFile] {
        [
            SessionLogFile(
                path: "/tmp/\(dayPath)/sample.jsonl",
                content: """
                {"timestamp":"2026-03-31T01:00:00Z","type":"session_meta","payload":{"cwd":"/Users/a007/Documents/trae_projects/效率工具/codex检测"}}
                {"timestamp":"2026-03-31T01:00:01Z","type":"turn_context","payload":{"cwd":"/Users/a007/Documents/trae_projects/效率工具/codex检测","model":"gpt-5.4"}}
                {"timestamp":"2026-03-31T01:00:05Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"input_tokens":1000,"cached_input_tokens":100,"output_tokens":50,"reasoning_output_tokens":0,"total_tokens":1050}}}}
                """
            )
        ]
    }
}

private struct MockProjectPricingClient: PricingClient {
    let result: Result<Data, Error>

    func fetchPricingJSON() async throws -> Data {
        try result.get()
    }
}

private let singleDayJSON = """
{
  "daily": [
    {
      "date": "Mar 31, 2026",
      "inputTokens": 281536117,
      "cachedInputTokens": 260530816,
      "outputTokens": 1764093,
      "reasoningOutputTokens": 623585,
      "totalTokens": 283300210,
      "costUSD": 127.915121,
      "models": {}
    }
  ],
  "totals": {
    "inputTokens": 281536117,
    "cachedInputTokens": 260530816,
    "outputTokens": 1764093,
    "reasoningOutputTokens": 623585,
    "totalTokens": 283300210,
    "costUSD": 127.915121
  }
}
"""

private let weeklyJSON = """
{
  "daily": [
    {
      "date": "Mar 26, 2026",
      "inputTokens": 444667,
      "cachedInputTokens": 392576,
      "outputTokens": 8654,
      "reasoningOutputTokens": 1517,
      "totalTokens": 453321,
      "costUSD": 0.35818150000000004,
      "models": {}
    },
    {
      "date": "Mar 29, 2026",
      "inputTokens": 42217853,
      "cachedInputTokens": 39070208,
      "outputTokens": 202251,
      "reasoningOutputTokens": 63934,
      "totalTokens": 42420104,
      "costUSD": 20.379698250000004,
      "models": {}
    },
    {
      "date": "Mar 30, 2026",
      "inputTokens": 47301374,
      "cachedInputTokens": 43893504,
      "outputTokens": 571746,
      "reasoningOutputTokens": 126801,
      "totalTokens": 47873120,
      "costUSD": 24.714013750000003,
      "models": {}
    },
    {
      "date": "Mar 31, 2026",
      "inputTokens": 281536117,
      "cachedInputTokens": 260530816,
      "outputTokens": 1764093,
      "reasoningOutputTokens": 623585,
      "totalTokens": 283300210,
      "costUSD": 127.915121,
      "models": {}
    }
  ],
  "totals": {
    "inputTokens": 371500011,
    "cachedInputTokens": 343887104,
    "outputTokens": 2546744,
    "reasoningOutputTokens": 815837,
    "totalTokens": 374046755,
    "costUSD": 173.3670145
  }
}
"""

private let projectPricingJSON = """
{
  "gpt-5.4": {
    "input_cost_per_token": 0.00000125,
    "output_cost_per_token": 0.00001,
    "cache_read_input_token_cost": 0.000000125
  }
}
"""
