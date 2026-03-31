import Foundation
import Testing
@testable import CodexMenuBarApp

@Test
func pricingParserBuildsPerMillionRows() async throws {
    let service = ModelPricingService(
        client: MockPricingClient(
            result: .success(Data(pricingJSON.utf8))
        )
    )

    let rows = try await service.fetchRows(for: ["gpt-5.4", "gpt-5.4-mini", "missing-model"])

    #expect(rows.count == 2)
    #expect(rows[0].model == "gpt-5.4")
    #expect(rows[0].inputPerMillionText == "$1.25/M")
    #expect(rows[0].outputPerMillionText == "$10.00/M")
    #expect(rows[0].cacheReadPerMillionText == "$0.12/M")
    #expect(rows[1].model == "gpt-5.4-mini")
}

@Test
func viewModelLoadsModelPricingRows() async throws {
    let runner = LocalMockCommandRunner()
    runner.results = [
        Result<CommandOutput, Error>.success(CommandOutput(standardOutput: Data(singleDayJSON.utf8), standardError: Data(), exitCode: 0)),
        Result<CommandOutput, Error>.success(CommandOutput(standardOutput: Data(weeklyJSON.utf8), standardError: Data(), exitCode: 0))
    ]

    let usageService = CodexUsageService(
        commandRunner: runner,
        executableLocator: CodexExecutableLocator(
            environment: [:],
            fileExists: { $0 == "/mock/bin/ccusage-codex" },
            nvmVersionsProvider: { ["/mock/bin/ccusage-codex"] }
        )
    )
    let pricingService = ModelPricingService(
        client: MockPricingClient(result: .success(Data(pricingJSON.utf8)))
    )
    let viewModel = MenuBarViewModel(service: usageService, pricingService: pricingService)

    await viewModel.refresh(now: ISO8601DateFormatter().date(from: "2026-03-31T10:00:00Z")!)

    let snapshot = await viewModel.snapshot
    #expect(snapshot.pricingRows.count == 2)
    #expect(snapshot.pricingRows[0].model == "gpt-5.4")
    #expect(snapshot.pricingRows[1].model == "gpt-5.4-mini")
}

private struct MockPricingClient: PricingClient {
    let result: Result<Data, Error>

    func fetchPricingJSON() async throws -> Data {
        try result.get()
    }
}

private final class LocalMockCommandRunner: CommandRunning, @unchecked Sendable {
    var results: [Result<CommandOutput, Error>] = []

    func run(_ invocation: CommandInvocation) async throws -> CommandOutput {
        guard !results.isEmpty else {
            fatalError("Missing stubbed result for \(invocation)")
        }

        return try results.removeFirst().get()
    }
}

private let pricingJSON = """
{
  "gpt-5.4": {
    "input_cost_per_token": 0.00000125,
    "output_cost_per_token": 0.00001,
    "cache_read_input_token_cost": 0.000000125
  },
  "gpt-5.4-mini": {
    "input_cost_per_token": 0.00000025,
    "output_cost_per_token": 0.000002,
    "cache_read_input_token_cost": 0.000000025
  }
}
"""

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
