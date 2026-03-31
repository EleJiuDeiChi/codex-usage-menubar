import Foundation
import Testing
@testable import CodexMenuBarApp

@Test
func projectUsageAggregatesTodayByCwd() async throws {
    let service = ProjectUsageService(
        sessionLogStore: MockSessionLogStore(
            files: [
                SessionLogFile(
                    path: "/Users/test/.codex/sessions/2026/03/31/rollout-a.jsonl",
                    content: sampleLogA
                ),
                SessionLogFile(
                    path: "/Users/test/.codex/sessions/2026/03/31/rollout-b.jsonl",
                    content: sampleLogB
                ),
                SessionLogFile(
                    path: "/Users/test/.codex/sessions/2026/03/31/rollout-c.jsonl",
                    content: sampleLogC
                )
            ]
        ),
        pricingService: ModelPricingService(
            client: MockProjectPricingClient(result: .success(Data(projectPricingJSON.utf8))),
            featuredModels: ["gpt-5.4", "gpt-5.4-mini"]
        )
    )

    let rows = try await service.fetchTodayProjectUsage(now: fixedNow, timezone: shanghaiTimeZone)

    #expect(rows.count == 3)
    #expect(rows[0].displayName == "效率工具 / codex检测")
    #expect(rows[0].costText == "$0.09")
    #expect(rows[0].inputTokensText == "10.0K")
    #expect(rows[0].outputTokensText == "100")

    #expect(rows[1].displayName == "project / codex检测")
    #expect(rows[1].costText == "$0.05")

    #expect(rows[2].displayName == "浏览器交互终端")
    #expect(rows[2].costText == "$0.04")
}

@Test
func projectNameFormatterDisambiguatesDuplicateLeafDirectories() {
    let rows = ProjectNameFormatter.formatDisplayNames(for: [
        "/Users/a/project/codex检测",
        "/Users/b/效率工具/codex检测",
        "/Users/c/browser"
    ])

    #expect(rows["/Users/a/project/codex检测"] == "project / codex检测")
    #expect(rows["/Users/b/效率工具/codex检测"] == "效率工具 / codex检测")
    #expect(rows["/Users/c/browser"] == "browser")
}

private let fixedNow = ISO8601DateFormatter().date(from: "2026-03-31T14:00:00Z")!
private let shanghaiTimeZone = TimeZone(identifier: "Asia/Shanghai")!

private struct MockSessionLogStore: SessionLogStoring {
    let files: [SessionLogFile]

    func listSessionFiles(for dayPath: String) throws -> [SessionLogFile] {
        files.filter { $0.path.contains(dayPath) }
    }
}

private struct MockProjectPricingClient: PricingClient {
    let result: Result<Data, Error>

    func fetchPricingJSON() async throws -> Data {
        try result.get()
    }
}

private let sampleLogA = """
{"timestamp":"2026-03-31T01:00:00Z","type":"session_meta","payload":{"cwd":"/Users/a007/Documents/trae_projects/效率工具/codex检测"}}
{"timestamp":"2026-03-31T01:00:01Z","type":"turn_context","payload":{"cwd":"/Users/a007/Documents/trae_projects/效率工具/codex检测","model":"gpt-5.4"}}
{"timestamp":"2026-03-31T01:00:05Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"input_tokens":10000,"cached_input_tokens":2000,"output_tokens":100,"reasoning_output_tokens":50,"total_tokens":10100}}}}
"""

private let sampleLogB = """
{"timestamp":"2026-03-31T02:00:00Z","type":"session_meta","payload":{"cwd":"/Users/other/project/codex检测"}}
{"timestamp":"2026-03-31T02:00:01Z","type":"turn_context","payload":{"cwd":"/Users/other/project/codex检测","model":"gpt-5.4-mini"}}
{"timestamp":"2026-03-31T02:00:05Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"input_tokens":12000,"cached_input_tokens":3000,"output_tokens":300,"reasoning_output_tokens":0,"total_tokens":12300}}}}
"""

private let sampleLogC = """
{"timestamp":"2026-03-31T03:00:00Z","type":"session_meta","payload":{"cwd":"/Users/a007/Documents/trae_projects/浏览器交互终端"}}
{"timestamp":"2026-03-31T03:00:01Z","type":"turn_context","payload":{"cwd":"/Users/a007/Documents/trae_projects/浏览器交互终端","model":"gpt-5.4-mini"}}
{"timestamp":"2026-03-31T03:00:05Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"input_tokens":9000,"cached_input_tokens":1000,"output_tokens":200,"reasoning_output_tokens":0,"total_tokens":9200}}}}
"""

private let projectPricingJSON = """
{
  "gpt-5.4": {
    "input_cost_per_token": 0.00001,
    "output_cost_per_token": 0.0001,
    "cache_read_input_token_cost": 0.000001
  },
  "gpt-5.4-mini": {
    "input_cost_per_token": 0.000005,
    "output_cost_per_token": 0.00002,
    "cache_read_input_token_cost": 0.0000005
  }
}
"""
