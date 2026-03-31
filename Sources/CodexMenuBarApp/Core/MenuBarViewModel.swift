import Foundation

struct MenuBarSnapshot: Sendable, Equatable {
    var menuBarTitle: String = "Codex --"
    var todayCostText: String = "--"
    var inputTokensText: String = "--"
    var outputTokensText: String = "--"
    var weeklyRows: [CodexUsageDay] = []
    var pricingRows: [ModelPricingRow] = []
    var projectRows: [ProjectUsageRow] = []
    var errorMessage: String?
    var lastUpdatedText: String = "从未"
}

actor MenuBarViewModel {
    private let service: CodexUsageService
    private let pricingService: ModelPricingService
    private let projectUsageService: ProjectUsageService
    private(set) var snapshot = MenuBarSnapshot()

    init(
        service: CodexUsageService = CodexUsageService(),
        pricingService: ModelPricingService = ModelPricingService(),
        projectUsageService: ProjectUsageService = ProjectUsageService()
    ) {
        self.service = service
        self.pricingService = pricingService
        self.projectUsageService = projectUsageService
    }

    func refresh(now: Date = Date()) async {
        let today = Self.dayString(from: now)
        let weekStart = Self.dayString(from: Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now)

        do {
            let todayValue = try await service.fetchDailyReport(since: today, until: today)
            let weeklyValue = try await service.fetchDailyReport(since: weekStart, until: today)

            snapshot.menuBarTitle = MenuBarTitleFormatter.makeTitle(from: todayValue)
            snapshot.todayCostText = Self.usd(todayValue.days.last?.costUSD ?? 0)
            snapshot.inputTokensText = TokenCountFormatter.format(todayValue.days.last?.inputTokens ?? 0)
            snapshot.outputTokensText = TokenCountFormatter.format(todayValue.days.last?.outputTokens ?? 0)
            snapshot.weeklyRows = weeklyValue.days
            snapshot.pricingRows = (try? await pricingService.fetchRows()) ?? []
            snapshot.projectRows = (try? await projectUsageService.fetchTodayProjectUsage(now: now)) ?? []
            snapshot.errorMessage = nil
            snapshot.lastUpdatedText = Self.timestamp(now)
        } catch let error as CommandRunnerError {
            snapshot = MenuBarSnapshot(
                menuBarTitle: "Codex --",
                errorMessage: Self.message(for: error),
                lastUpdatedText: Self.timestamp(now)
            )
        } catch {
            snapshot = MenuBarSnapshot(
                menuBarTitle: "Codex --",
                errorMessage: error.localizedDescription,
                lastUpdatedText: Self.timestamp(now)
            )
        }
    }

    private static func message(for error: CommandRunnerError) -> String {
        switch error {
        case let .executionFailed(message):
            return message
        case let .nonZeroExit(_, message):
            return message
        }
    }

    private static func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func usd(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
    private static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
