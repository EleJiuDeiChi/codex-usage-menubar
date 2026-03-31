import Foundation

struct ModelPricingRow: Sendable, Equatable {
    let model: String
    let inputPerMillionText: String
    let outputPerMillionText: String
    let cacheReadPerMillionText: String
}

struct ModelPricing: Sendable, Equatable {
    let inputCostPerToken: Double?
    let outputCostPerToken: Double?
    let cacheReadCostPerToken: Double?
}

protocol PricingClient: Sendable {
    func fetchPricingJSON() async throws -> Data
}

struct ModelPricingService: Sendable {
    let client: PricingClient
    let featuredModels: [String]

    init(
        client: PricingClient = LiteLLMPricingClient(),
        featuredModels: [String] = ["gpt-5.4", "gpt-5.4-mini", "gpt-5.3-codex-spark"]
    ) {
        self.client = client
        self.featuredModels = featuredModels
    }

    func fetchRows(for models: [String]? = nil) async throws -> [ModelPricingRow] {
        let catalog = try await fetchPricing(for: models)
        let targets = models ?? featuredModels

        return targets.compactMap { model in
            guard let pricing = catalog[model] else {
                return nil
            }

            return ModelPricingRow(
                model: model,
                inputPerMillionText: Self.perMillion(pricing.inputCostPerToken),
                outputPerMillionText: Self.perMillion(pricing.outputCostPerToken),
                cacheReadPerMillionText: Self.perMillion(pricing.cacheReadCostPerToken)
            )
        }
    }

    func fetchPricing(for models: [String]? = nil) async throws -> [String: ModelPricing] {
        let data = try await client.fetchPricingJSON()
        let payload = try JSONDecoder().decode([String: RawModelPricing].self, from: data)
        let targets = models ?? featuredModels

        var result: [String: ModelPricing] = [:]
        for model in targets {
            guard let pricing = payload[model] else { continue }
            result[model] = ModelPricing(
                inputCostPerToken: pricing.input_cost_per_token,
                outputCostPerToken: pricing.output_cost_per_token,
                cacheReadCostPerToken: pricing.cache_read_input_token_cost
            )
        }
        return result
    }

    private static func perMillion(_ costPerToken: Double?) -> String {
        guard let costPerToken else {
            return "--"
        }

        return String(format: "$%.2f/M", costPerToken * 1_000_000)
    }
}

struct LiteLLMPricingClient: PricingClient {
    let session: URLSession
    let url: URL

    init(
        session: URLSession = .shared,
        url: URL = URL(string: "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json")!
    ) {
        self.session = session
        self.url = url
    }

    func fetchPricingJSON() async throws -> Data {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw CommandRunnerError.executionFailed("Failed to fetch LiteLLM pricing: HTTP \(http.statusCode)")
        }

        return data
    }
}

private struct RawModelPricing: Decodable {
    let input_cost_per_token: Double?
    let output_cost_per_token: Double?
    let cache_read_input_token_cost: Double?
}
