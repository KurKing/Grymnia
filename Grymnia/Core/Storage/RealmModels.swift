import Foundation
import GrymniaStatementParser
import RealmSwift

final class AccountObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var bankRaw: String
    @Persisted var alias: String
    @Persisted var cardSuffix: String?
    @Persisted var currency: String
    @Persisted var createdAt: Date
}

final class TransactionObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var bankRaw: String
    @Persisted var accountID: String
    @Persisted var accountAlias: String
    @Persisted var cardSuffix: String?
    @Persisted var operationDate: Date
    @Persisted var postingDate: Date?
    @Persisted var merchant: String
    @Persisted var rawDescription: String
    @Persisted var mcc: Int?
    @Persisted var amount: String
    @Persisted var currency: String
    @Persisted var originalAmount: String?
    @Persisted var originalCurrency: String?
    @Persisted var exchangeRate: String?
    @Persisted var cashback: String?
    @Persisted var fee: String?
    @Persisted var balanceAfter: String?
    @Persisted var typeRaw: String
    @Persisted var statusRaw: String
    @Persisted var categoryRaw: String
    @Persisted var importFingerprint: String
    @Persisted var importedAt: Date
}

extension TransactionObject {
    convenience init(transaction: NormalizedTransaction) {
        self.init()
        id = transaction.id
        bankRaw = transaction.bank.rawValue
        accountID = transaction.accountID
        accountAlias = transaction.accountAlias
        cardSuffix = transaction.cardSuffix
        operationDate = transaction.operationDate
        postingDate = transaction.postingDate
        merchant = transaction.merchant
        rawDescription = transaction.rawDescription
        mcc = transaction.mcc
        amount = transaction.amount.storageString
        currency = transaction.currency
        originalAmount = transaction.originalAmount?.storageString
        originalCurrency = transaction.originalCurrency
        exchangeRate = transaction.exchangeRate?.storageString
        cashback = transaction.cashback?.storageString
        fee = transaction.fee?.storageString
        balanceAfter = transaction.balanceAfter?.storageString
        typeRaw = transaction.type.rawValue
        statusRaw = transaction.status.rawValue
        categoryRaw = transaction.category.rawValue
        importFingerprint = transaction.importFingerprint
        importedAt = Date()
    }

    var snapshot: NormalizedTransaction {
        NormalizedTransaction(
            id: id,
            bank: Bank(rawValue: bankRaw) ?? .monobank,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: cardSuffix,
            operationDate: operationDate,
            postingDate: postingDate,
            merchant: merchant,
            rawDescription: rawDescription,
            mcc: mcc,
            amount: Decimal(storage: amount),
            currency: currency,
            originalAmount: originalAmount.map(Decimal.init(storage:)),
            originalCurrency: originalCurrency,
            exchangeRate: exchangeRate.map(Decimal.init(storage:)),
            cashback: cashback.map(Decimal.init(storage:)),
            fee: fee.map(Decimal.init(storage:)),
            balanceAfter: balanceAfter.map(Decimal.init(storage:)),
            type: TransactionType(rawValue: typeRaw) ?? .expense,
            status: TransactionStatus(rawValue: statusRaw) ?? .booked,
            category: TransactionCategory(rawValue: categoryRaw) ?? .other,
            importFingerprint: importFingerprint
        )
    }
}

extension AccountObject {
    convenience init(importSummary: StatementImport) {
        self.init()
        id = importSummary.accountID
        bankRaw = importSummary.bank.rawValue
        alias = importSummary.accountAlias
        cardSuffix = importSummary.transactions.first?.cardSuffix
        currency = importSummary.transactions.first?.currency ?? "UAH"
        createdAt = Date()
    }
}

extension Decimal {
    nonisolated init(storage: String) {
        self = Decimal(string: storage, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    nonisolated var storageString: String {
        NSDecimalNumber(decimal: self).stringValue
    }
}
