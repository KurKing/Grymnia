import Foundation
import PDFKit
import Testing
@testable import GrymniaStatementParser

struct MonobankPDFParsingTests {
    @Test func parsesMonoPDFStatement() throws {
        let pdfURL = repoRoot().appendingPathComponent("mono.pdf")
        let pdf = try #require(PDFDocument(url: pdfURL))
        let parser = MonobankParser()
        let text = try PDFTextExtractor.text(from: pdf)

        #expect(parser.canParse(text))

        let importResult = try parser.parse(pdf)
        let transactions = importResult.transactions
        let first = try #require(transactions.first)
        let last = try #require(transactions.last)
        let total = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        let fingerprints = Set(transactions.map(\.importFingerprint))

        #expect(importResult.bank == .monobank)
        #expect(importResult.accountID == "monobank-uah")
        #expect(importResult.accountAlias == "Monobank • UAH")
        #expect(importResult.duplicateCount == 0)
        #expect(transactions.count == 86)
        #expect(fingerprints.count == transactions.count)
        #expect(transactions.allSatisfy { !$0.id.isEmpty && $0.id == $0.importFingerprint })
        #expect(transactions.allSatisfy { !$0.merchant.isEmpty && !$0.rawDescription.isEmpty })
        #expect(transactions.allSatisfy { $0.bank == .monobank && $0.currency == "UAH" })

        #expect(first.operationDate == date(2026, 7, 28, 15, 55, 35))
        #expect(first.merchant == "АТБ")
        #expect(first.rawDescription.contains("АТБ"))
        #expect(first.mcc == 5499)
        #expect(first.amount == Decimal(string: "-1047.84"))
        #expect(first.balanceAfter == Decimal(string: "9908.2"))
        #expect(first.type == .expense)
        #expect(first.category == .groceries)

        #expect(transactions.contains { transaction in
            transaction.operationDate == date(2026, 7, 23, 15, 48, 57)
                && transaction.merchant == "Від: Tereshpol` s `kyy Anton"
                && transaction.mcc == 6012
                && transaction.amount == Decimal(3000)
                && transaction.type == .income
                && transaction.category == .income
        })

        #expect(last.operationDate == date(2026, 7, 3, 19, 6, 51))
        #expect(last.merchant == "Повернись живим")
        #expect(last.mcc == 4829)
        #expect(last.amount == Decimal(string: "-149.76"))
        #expect(last.balanceAfter == Decimal(string: "5386.6"))
        #expect(last.type == .expense)
        #expect(last.category == .other)
        #expect(total == Decimal(string: "3017.2"))
    }

    private func repoRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        _ second: Int
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return components.date!
    }
}
