import Foundation

public struct NormalizedTransaction: Identifiable, Hashable, Sendable {
    public var id: String
    public var bank: Bank
    public var accountID: String
    public var accountAlias: String
    public var cardSuffix: String?
    public var operationDate: Date
    public var postingDate: Date?
    public var merchant: String
    public var rawDescription: String
    public var mcc: Int?
    public var amount: Decimal
    public var currency: String
    public var originalAmount: Decimal?
    public var originalCurrency: String?
    public var exchangeRate: Decimal?
    public var cashback: Decimal?
    public var fee: Decimal?
    public var balanceAfter: Decimal?
    public var type: TransactionType
    public var status: TransactionStatus
    public var category: TransactionCategory
    public var importFingerprint: String

    public init(
        id: String,
        bank: Bank,
        accountID: String,
        accountAlias: String,
        cardSuffix: String?,
        operationDate: Date,
        postingDate: Date?,
        merchant: String,
        rawDescription: String,
        mcc: Int?,
        amount: Decimal,
        currency: String,
        originalAmount: Decimal?,
        originalCurrency: String?,
        exchangeRate: Decimal?,
        cashback: Decimal?,
        fee: Decimal?,
        balanceAfter: Decimal?,
        type: TransactionType,
        status: TransactionStatus,
        category: TransactionCategory,
        importFingerprint: String
    ) {
        self.id = id
        self.bank = bank
        self.accountID = accountID
        self.accountAlias = accountAlias
        self.cardSuffix = cardSuffix
        self.operationDate = operationDate
        self.postingDate = postingDate
        self.merchant = merchant
        self.rawDescription = rawDescription
        self.mcc = mcc
        self.amount = amount
        self.currency = currency
        self.originalAmount = originalAmount
        self.originalCurrency = originalCurrency
        self.exchangeRate = exchangeRate
        self.cashback = cashback
        self.fee = fee
        self.balanceAfter = balanceAfter
        self.type = type
        self.status = status
        self.category = category
        self.importFingerprint = importFingerprint
    }
}

public struct StatementImport: Identifiable, Sendable {
    public var id = UUID()
    public var bank: Bank
    public var accountID: String
    public var accountAlias: String
    public var transactions: [NormalizedTransaction]
    public var duplicateCount: Int

    public init(
        id: UUID = UUID(),
        bank: Bank,
        accountID: String,
        accountAlias: String,
        transactions: [NormalizedTransaction],
        duplicateCount: Int = 0
    ) {
        self.id = id
        self.bank = bank
        self.accountID = accountID
        self.accountAlias = accountAlias
        self.transactions = transactions
        self.duplicateCount = duplicateCount
    }
}
