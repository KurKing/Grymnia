import CryptoKit
import Foundation

enum TransactionFingerprint {
    static func make(
        bank: Bank,
        accountID: String,
        operationDate: Date,
        postingDate: Date?,
        merchant: String,
        amount: Decimal,
        currency: String,
        originalAmount: Decimal?,
        originalCurrency: String?,
        cardSuffix: String?,
        rawDescription: String,
        occurrenceIndex: Int
    ) -> String {
        let payload = [
            bank.rawValue,
            accountID,
            Self.format(operationDate),
            postingDate.map(Self.format) ?? "",
            MerchantNormalizer.key(merchant),
            NSDecimalNumber(decimal: amount).stringValue,
            currency.uppercased(),
            originalAmount.map { NSDecimalNumber(decimal: $0).stringValue } ?? "",
            originalCurrency?.uppercased() ?? "",
            cardSuffix ?? "",
            MerchantNormalizer.key(rawDescription),
            String(occurrenceIndex)
        ].joined(separator: "|")

        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    nonisolated private static func format(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
