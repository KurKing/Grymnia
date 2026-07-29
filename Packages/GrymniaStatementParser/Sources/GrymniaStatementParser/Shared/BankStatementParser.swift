import Foundation
import PDFKit

public protocol BankStatementParser {
    func canParse(_ text: String) -> Bool
    func parse(_ pdf: PDFDocument) throws -> StatementImport
}

public enum ParserError: LocalizedError {
    case noText
    case unsupportedStatement
    case noTransactions(bank: Bank)

    public var errorDescription: String? {
        switch self {
        case .noText:
            "PDF has no extractable text."
        case .unsupportedStatement:
            "This PDF does not look like a supported bank statement."
        case .noTransactions(let bank):
            "No transactions found in \(bank.displayName) statement."
        }
    }
}
