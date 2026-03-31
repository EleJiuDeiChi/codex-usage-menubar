import Foundation

enum UsageParser {
    static func parseDailyReport(from data: Data) throws -> CodexUsageReport {
        let decoder = JSONDecoder()
        let raw = try decoder.decode(RawDailyReport.self, from: data)

        return CodexUsageReport(
            days: raw.daily.map {
                CodexUsageDay(
                    dateLabel: $0.date,
                    inputTokens: $0.inputTokens,
                    cachedInputTokens: $0.cachedInputTokens,
                    outputTokens: $0.outputTokens,
                    reasoningOutputTokens: $0.reasoningOutputTokens,
                    totalTokens: $0.totalTokens,
                    costUSD: $0.costUSD
                )
            },
            totals: CodexUsageTotals(
                inputTokens: raw.totals.inputTokens,
                cachedInputTokens: raw.totals.cachedInputTokens,
                outputTokens: raw.totals.outputTokens,
                reasoningOutputTokens: raw.totals.reasoningOutputTokens,
                totalTokens: raw.totals.totalTokens,
                costUSD: raw.totals.costUSD
            )
        )
    }
}

private struct RawDailyReport: Decodable {
    let daily: [RawDailyUsage]
    let totals: RawTotals
}

private struct RawDailyUsage: Decodable {
    let date: String
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningOutputTokens: Int
    let totalTokens: Int
    let costUSD: Double
}

private struct RawTotals: Decodable {
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningOutputTokens: Int
    let totalTokens: Int
    let costUSD: Double
}
