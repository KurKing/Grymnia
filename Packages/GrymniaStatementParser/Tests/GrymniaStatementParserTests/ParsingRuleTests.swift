import Foundation
@testable import GrymniaStatementParser
import Testing

struct ParsingRuleTests {
    @Test func merchantNormalizationHandlesKnownMerchants() {
        #expect(MerchantNormalizer.normalized("SILPO MARKET #123") == "Silpo")
        #expect(MerchantNormalizer.normalized("SHOP EPITSENTR") == "Epicentr")
    }

    @Test func mccCategoryTakesPriority() {
        let draft = ParsedTransactionDraft(
            bank: .monobank,
            accountID: "test-account",
            accountAlias: "Test",
            cardSuffix: nil,
            operationDate: Date(timeIntervalSince1970: 0),
            postingDate: nil,
            merchant: "Unknown",
            rawDescription: "Unknown",
            mcc: 5411,
            amount: -100,
            currency: "UAH",
            originalAmount: nil,
            originalCurrency: nil,
            exchangeRate: nil,
            cashback: nil,
            fee: nil,
            balanceAfter: nil,
            type: .expense,
            status: .booked
        )

        #expect(CategoryResolver.category(for: draft) == .groceries)
    }

    @Test func fingerprintIsStableForSameInput() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let first = TransactionFingerprint.make(
            bank: .monobank,
            accountID: "account",
            operationDate: date,
            postingDate: nil,
            merchant: "Silpo",
            amount: -42.50,
            currency: "UAH",
            originalAmount: nil,
            originalCurrency: nil,
            cardSuffix: "1234",
            rawDescription: "SILPO MARKET #123",
            occurrenceIndex: 1
        )
        let second = TransactionFingerprint.make(
            bank: .monobank,
            accountID: "account",
            operationDate: date,
            postingDate: nil,
            merchant: "Silpo",
            amount: -42.50,
            currency: "UAH",
            originalAmount: nil,
            originalCurrency: nil,
            cardSuffix: "1234",
            rawDescription: "SILPO MARKET #123",
            occurrenceIndex: 1
        )

        #expect(first == second)
    }

    @Test func creditAgricoleParsesWholeNumberAccountTopUp() throws {
        let text = """
        Credit Agricole
        1 01.07.2026 01.07.2026 Поповнення рахунку UAH -50000
        """

        let importResult = try CreditAgricoleParser().parse(text: text)
        let transaction = try #require(importResult.transactions.first)

        #expect(importResult.transactions.count == 1)
        #expect(transaction.merchant == "Поповнення рахунку")
        #expect(transaction.amount == Decimal(-50000))
        #expect(transaction.currency == "UAH")
        #expect(transaction.type == .expense)
    }

    @Test func monobankParsesWholeNumberAccountTopUp() throws {
        let text = """
        monobank
        01.07.2026 12:34:56 Поповнення рахунку 6012 -50000 -50000 UAH — 0 0 1000
        """

        let importResult = try MonobankParser().parse(text: text)
        let transaction = try #require(importResult.transactions.first)

        #expect(importResult.transactions.count == 1)
        #expect(transaction.merchant == "Поповнення рахунку")
        #expect(transaction.mcc == 6012)
        #expect(transaction.amount == Decimal(-50000))
        #expect(transaction.currency == "UAH")
        #expect(transaction.type == .expense)
    }
}
