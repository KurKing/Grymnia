import Foundation

enum ParsingHelpers {
    static let ukrainianPOSIX: Locale = Locale(identifier: "uk_UA_POSIX")

    static func decimal(from raw: String) -> Decimal? {
        var value = raw
            .replacingOccurrences(of: "\u{00a0}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "грн", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "UAH", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var sign: Decimal = 1
        if value.hasPrefix("+") {
            value.removeFirst()
        } else if value.hasPrefix("-") || value.hasPrefix("−") {
            value.removeFirst()
            sign = -1
        }

        guard let decimal = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        return decimal * sign
    }

    static func date(_ raw: String) -> Date? {
        for format in ["dd.MM.yyyy HH:mm:ss", "dd.MM.yyyy HH:mm", "dd.MM.yyyy"] {
            let formatter = DateFormatter()
            formatter.locale = ukrainianPOSIX
            formatter.timeZone = TimeZone(identifier: "Europe/Kyiv")
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) {
                return date
            }
        }
        return nil
    }

    static func transactionType(amount: Decimal, rawDescription: String) -> TransactionType {
        let key = MerchantNormalizer.key(rawDescription)
        if key.contains("КОМІС") || key.contains("ПЛАТАЗАКОНВЕРТАЦ") || key.contains("FEE") {
            return .fee
        }
        if key.contains("БЛОКУВАН") || key.contains("HOLD") {
            return .hold
        }
        if amount > 0, key.contains("ПОВЕРНЕН") || key.contains("REFUND") {
            return .refund
        }
        return amount >= 0 ? .income : .expense
    }

    static func occurrenceIndexes(for drafts: [ParsedTransactionDraft]) -> [Int] {
        var counts: [String: Int] = [:]
        return drafts.map { draft in
            let key = [
                draft.bank.rawValue,
                draft.accountID,
                formattedDay(draft.operationDate),
                MerchantNormalizer.key(draft.merchant),
                NSDecimalNumber(decimal: draft.amount).stringValue,
                draft.currency
            ].joined(separator: "|")
            let next = (counts[key] ?? 0) + 1
            counts[key] = next
            return next
        }
    }

    private static func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = ukrainianPOSIX
        formatter.timeZone = TimeZone(identifier: "Europe/Kyiv")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
