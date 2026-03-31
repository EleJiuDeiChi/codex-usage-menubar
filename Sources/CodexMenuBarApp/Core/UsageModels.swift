import Foundation

struct CodexUsageReport: Sendable, Equatable {
    let days: [CodexUsageDay]
    let totals: CodexUsageTotals

    var totalCostUSD: Double { totals.costUSD }
    var totalInputTokens: Int { totals.inputTokens }
}

struct CodexUsageDay: Sendable, Equatable {
    let dateLabel: String
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningOutputTokens: Int
    let totalTokens: Int
    let costUSD: Double
}

struct CodexUsageTotals: Sendable, Equatable {
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningOutputTokens: Int
    let totalTokens: Int
    let costUSD: Double
}

enum MenuBarTitleFormatter {
    static func makeTitle(from report: CodexUsageReport?) -> String {
        guard let report else {
            return "Codex --"
        }

        return String(format: "Codex $%.2f", report.days.last?.costUSD ?? 0)
    }
}
