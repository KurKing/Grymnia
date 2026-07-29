import Foundation
import PDFKit

public struct ParserRegistry {
    public var parsers: [BankStatementParser] = [
        MonobankParser(),
        CreditAgricoleParser()
    ]

    public init(parsers: [BankStatementParser]? = nil) {
        if let parsers {
            self.parsers = parsers
        }
    }

    public func parse(_ document: PDFDocument) throws -> StatementImport {
        let text = try PDFTextExtractor.text(from: document)
        guard let parser = parsers.first(where: { $0.canParse(text) }) else {
            throw ParserError.unsupportedStatement
        }
        return try parser.parse(document)
    }
}
