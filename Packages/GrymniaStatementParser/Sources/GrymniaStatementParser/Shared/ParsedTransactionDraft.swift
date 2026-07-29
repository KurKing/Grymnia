import Foundation

struct ParsedTransactionDraft: Hashable {
    var bank: Bank
    var accountID: String
    var accountAlias: String
    var cardSuffix: String?
    var operationDate: Date
    var postingDate: Date?
    var merchant: String
    var rawDescription: String
    var mcc: Int?
    var amount: Decimal
    var currency: String
    var originalAmount: Decimal?
    var originalCurrency: String?
    var exchangeRate: Decimal?
    var cashback: Decimal?
    var fee: Decimal?
    var balanceAfter: Decimal?
    var type: TransactionType
    var status: TransactionStatus
}

extension ParsedTransactionDraft {
    func normalized(occurrenceIndex: Int) -> NormalizedTransaction {
        var copy = self
        copy.merchant = MerchantNormalizer.normalized(merchant)
        let fingerprint = TransactionFingerprint.make(
            bank: bank,
            accountID: accountID,
            operationDate: operationDate,
            postingDate: postingDate,
            merchant: copy.merchant,
            amount: amount,
            currency: currency,
            originalAmount: originalAmount,
            originalCurrency: originalCurrency,
            cardSuffix: cardSuffix,
            rawDescription: rawDescription,
            occurrenceIndex: occurrenceIndex
        )

        return NormalizedTransaction(
            id: fingerprint,
            bank: bank,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: cardSuffix,
            operationDate: operationDate,
            postingDate: postingDate,
            merchant: copy.merchant,
            rawDescription: rawDescription,
            mcc: mcc,
            amount: amount,
            currency: currency,
            originalAmount: originalAmount,
            originalCurrency: originalCurrency,
            exchangeRate: exchangeRate,
            cashback: cashback,
            fee: fee,
            balanceAfter: balanceAfter,
            type: type,
            status: status,
            category: CategoryResolver.category(for: copy),
            importFingerprint: fingerprint
        )
    }
}
