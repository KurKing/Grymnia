import Foundation
import PDFKit

struct ParserRegistry {
    var parsers: [BankStatementParser] = [
        MonobankParser(),
        CreditAgricoleParser()
    ]

    func parse(_ document: PDFDocument) throws -> StatementImport {
        let text = try PDFTextExtractor.text(from: document)
        guard let parser = parsers.first(where: { $0.canParse(text) }) else {
            throw ParserError.unsupportedStatement
        }
        return try parser.parse(document)
    }
}
