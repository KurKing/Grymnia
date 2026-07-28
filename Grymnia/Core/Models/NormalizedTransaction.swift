import Foundation

struct NormalizedTransaction: Identifiable, Hashable {
    var id: String
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
    var category: TransactionCategory
    var importFingerprint: String
}

struct StatementImport: Identifiable {
    var id = UUID()
    var bank: Bank
    var accountID: String
    var accountAlias: String
    var transactions: [NormalizedTransaction]
    var duplicateCount: Int = 0
}
