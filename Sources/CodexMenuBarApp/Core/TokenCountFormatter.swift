import Foundation

enum TokenCountFormatter {
    static func format(_ value: Int) -> String {
        let absolute = Double(abs(value))
        let sign = value < 0 ? "-" : ""

        switch absolute {
        case 1_000_000...:
            return "\(sign)\(decimal(absolute / 1_000_000, rounded: true))M"
        case 1_000...:
            return "\(sign)\(decimal(absolute / 1_000, rounded: false))K"
        default:
            return "\(value)"
        }
    }

    private static func decimal(_ value: Double, rounded: Bool) -> String {
        let scaled = value * 10
        let adjusted = rounded ? scaled.rounded() / 10 : floor(scaled) / 10
        return String(format: "%.1f", adjusted)
    }
}
