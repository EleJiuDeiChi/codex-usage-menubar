import Foundation
import Testing
@testable import CodexMenuBarApp

@Test
func parserDecodesSingleDayReport() throws {
    let report = try UsageParser.parseDailyReport(from: Data(singleDayJSON.utf8))

    #expect(report.days.count == 1)
    #expect(report.days[0].dateLabel == "Mar 31, 2026")
    #expect(report.days[0].inputTokens == 281_536_117)
    #expect(report.days[0].outputTokens == 1_764_093)
    #expect(report.days[0].costUSD == 127.915121)
    #expect(report.totalCostUSD == 127.915121)
}

@Test
func parserDecodesSevenDayReport() throws {
    let report = try UsageParser.parseDailyReport(from: Data(weeklyJSON.utf8))

    #expect(report.days.count == 4)
    #expect(report.days.last?.dateLabel == "Mar 31, 2026")
    #expect(report.days.last?.costUSD == 127.915121)
    #expect(report.totalInputTokens == 371_500_011)
}

@Test
func menuBarTitleUsesRoundedUsdValue() {
    let report = CodexUsageReport(
        days: [
            CodexUsageDay(
                dateLabel: "Mar 31, 2026",
                inputTokens: 1,
                cachedInputTokens: 0,
                outputTokens: 2,
                reasoningOutputTokens: 0,
                totalTokens: 3,
                costUSD: 127.915121
            )
        ],
        totals: .init(
            inputTokens: 1,
            cachedInputTokens: 0,
            outputTokens: 2,
            reasoningOutputTokens: 0,
            totalTokens: 3,
            costUSD: 127.915121
        )
    )

    #expect(MenuBarTitleFormatter.makeTitle(from: report) == "Codex $127.92")
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
      "models": {
        "gpt-5.4": {
          "inputTokens": 222517499,
          "cachedInputTokens": 205719552,
          "outputTokens": 947767,
          "reasoningOutputTokens": 196893,
          "totalTokens": 223465266,
          "isFallback": false
        }
      }
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
