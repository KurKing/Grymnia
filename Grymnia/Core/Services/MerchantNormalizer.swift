import Foundation

enum MerchantNormalizer {
    static func normalized(_ value: String) -> String {
        let folded = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "uk_UA"))
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if folded.contains("SILPO") || folded.contains("СІЛЬПО") {
            return "Silpo"
        }
        if folded.contains("EPIT") || folded.contains("EPITSENTR") || folded.contains("ЕПІЦЕНТР") {
            return "Epicentr"
        }
        if folded.contains("MCDONALD") || folded.contains("MAKDONALD") || folded.contains("МАКДОНАЛ") {
            return "McDonald's"
        }
        if folded.contains("AZK") || folded.contains("OKKO") || folded.contains("WOG") {
            return folded.contains("OKKO") ? "OKKO" : folded.contains("WOG") ? "WOG" : "AZK"
        }
        if folded.contains("THRASH") {
            return "Thrash"
        }
        if folded.contains("LIQPAY") && folded.contains("CAMPANIA") {
            return "Campania"
        }

        return cleanedDisplayName(value)
    }

    static func key(_ value: String) -> String {
        normalized(value)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "uk_UA"))
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined()
    }

    private static func cleanedDisplayName(_ value: String) -> String {
        let withoutParentheses = value.replacing(/\([^)]*\)/, with: "")
        let compact = withoutParentheses
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !compact.isEmpty else { return "Unknown merchant" }
        return compact
    }
}
