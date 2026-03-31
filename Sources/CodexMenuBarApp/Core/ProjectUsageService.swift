import Foundation

struct ProjectUsageRow: Sendable, Equatable {
    let cwd: String
    let displayName: String
    let costText: String
    let inputTokensText: String
    let outputTokensText: String
}

struct SessionLogFile: Sendable, Equatable {
    let path: String
    let content: String
}

protocol SessionLogStoring: Sendable {
    func listSessionFiles(for dayPath: String) throws -> [SessionLogFile]
}

struct ProjectUsageService: Sendable {
    let sessionLogStore: SessionLogStoring
    let pricingService: ModelPricingService

    init(
        sessionLogStore: SessionLogStoring = FileSystemSessionLogStore(),
        pricingService: ModelPricingService = ModelPricingService()
    ) {
        self.sessionLogStore = sessionLogStore
        self.pricingService = pricingService
    }

    func fetchTodayProjectUsage(now: Date = Date(), timezone: TimeZone = TimeZone(identifier: "Asia/Shanghai")!) async throws -> [ProjectUsageRow] {
        let dayPath = Self.dayPath(from: now, timezone: timezone)
        let files = try sessionLogStore.listSessionFiles(for: dayPath)
        let projectUsage = parse(files: files)
        let models = Array(Set(projectUsage.values.flatMap(\.models.keys))).sorted()
        let pricing = try await pricingService.fetchPricing(for: models)
        let displayNames = ProjectNameFormatter.formatDisplayNames(for: Array(projectUsage.keys))

        let ranked: [(usage: AggregatedProjectUsage, cost: Double)] = projectUsage.values
            .map { usage in
                let totalCost = cost(for: usage, pricing: pricing)
                return (usage: usage, cost: totalCost)
            }
            .sorted {
                if $0.cost == $1.cost {
                    return (displayNames[$0.usage.cwd] ?? $0.usage.cwd) < (displayNames[$1.usage.cwd] ?? $1.usage.cwd)
                }
                return $0.cost > $1.cost
            }

        return ranked.map { item in
            ProjectUsageRow(
                cwd: item.usage.cwd,
                displayName: displayNames[item.usage.cwd] ?? item.usage.cwd,
                costText: String(format: "$%.2f", item.cost),
                inputTokensText: TokenCountFormatter.format(item.usage.inputTokens),
                outputTokensText: TokenCountFormatter.format(item.usage.outputTokens)
            )
        }
    }

    private func parse(files: [SessionLogFile]) -> [String: AggregatedProjectUsage] {
        var result: [String: AggregatedProjectUsage] = [:]

        for file in files {
            var currentCwd: String?
            var currentModel: String?

            for line in file.content.split(whereSeparator: \.isNewline) {
                guard let data = line.data(using: .utf8),
                      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let type = root["type"] as? String else {
                    continue
                }

                if type == "session_meta" || type == "turn_context" {
                    if let payload = root["payload"] as? [String: Any] {
                        if let cwd = payload["cwd"] as? String, !cwd.isEmpty {
                            currentCwd = cwd
                        }
                        if let model = payload["model"] as? String, !model.isEmpty {
                            currentModel = model
                        }
                    }
                    continue
                }

                guard type == "event_msg",
                      let payload = root["payload"] as? [String: Any],
                      (payload["type"] as? String) == "token_count",
                      let info = payload["info"] as? [String: Any],
                      let usage = info["last_token_usage"] as? [String: Any],
                      let cwd = currentCwd else {
                    continue
                }

                let input = usage["input_tokens"] as? Int ?? 0
                let cached = usage["cached_input_tokens"] as? Int ?? 0
                let output = usage["output_tokens"] as? Int ?? 0
                let reasoning = usage["reasoning_output_tokens"] as? Int ?? 0

                var aggregate = result[cwd] ?? AggregatedProjectUsage(cwd: cwd)
                aggregate.inputTokens += input
                aggregate.cachedInputTokens += cached
                aggregate.outputTokens += output
                aggregate.reasoningOutputTokens += reasoning

                if let currentModel {
                    var modelUsage = aggregate.models[currentModel] ?? .init()
                    modelUsage.inputTokens += input
                    modelUsage.cachedInputTokens += cached
                    modelUsage.outputTokens += output
                    aggregate.models[currentModel] = modelUsage
                }

                result[cwd] = aggregate
            }
        }

        return result
    }

    private func cost(for usage: AggregatedProjectUsage, pricing: [String: ModelPricing]) -> Double {
        usage.models.reduce(into: 0.0) { total, item in
            let (model, modelUsage) = item
            guard let price = pricing[model] else { return }
            let nonCachedInput = max(modelUsage.inputTokens - modelUsage.cachedInputTokens, 0)
            total += (Double(nonCachedInput) / 1_000_000) * (price.inputCostPerToken ?? 0) * 1_000_000
            total += (Double(modelUsage.cachedInputTokens) / 1_000_000) * (price.cacheReadCostPerToken ?? 0) * 1_000_000
            total += (Double(modelUsage.outputTokens) / 1_000_000) * (price.outputCostPerToken ?? 0) * 1_000_000
        }
    }

    private static func dayPath(from date: Date, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timezone
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct ProjectNameFormatter {
    static func formatDisplayNames(for paths: [String]) -> [String: String] {
        let leafCounts = Dictionary(grouping: paths, by: { URL(fileURLWithPath: $0).lastPathComponent })
            .mapValues(\.count)

        var result: [String: String] = [:]
        for path in paths {
            let url = URL(fileURLWithPath: path)
            let leaf = url.lastPathComponent
            if leafCounts[leaf, default: 0] > 1 {
                let parent = url.deletingLastPathComponent().lastPathComponent
                result[path] = "\(parent) / \(leaf)"
            } else {
                result[path] = leaf
            }
        }
        return result
    }
}

private struct AggregatedProjectUsage {
    struct ModelUsage {
        var inputTokens: Int = 0
        var cachedInputTokens: Int = 0
        var outputTokens: Int = 0
    }

    let cwd: String
    var inputTokens: Int = 0
    var cachedInputTokens: Int = 0
    var outputTokens: Int = 0
    var reasoningOutputTokens: Int = 0
    var models: [String: ModelUsage] = [:]
}

struct FileSystemSessionLogStore: SessionLogStoring {
    func listSessionFiles(for dayPath: String) throws -> [SessionLogFile] {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/sessions")
            .appendingPathComponent(dayPath)

        guard let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else {
            return []
        }

        var files: [SessionLogFile] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "jsonl" {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            files.append(SessionLogFile(path: fileURL.path, content: content))
        }
        return files
    }
}
