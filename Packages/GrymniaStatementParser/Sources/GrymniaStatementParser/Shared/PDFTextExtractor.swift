import Foundation
import PDFKit

enum PDFTextExtractor {
    static func text(from document: PDFDocument) throws -> String {
        var pages: [String] = []
        for index in 0..<document.pageCount {
            if let text = document.page(at: index)?.string, !text.isEmpty {
                pages.append(text)
            }
        }

        let output = pages.joined(separator: "\n")
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParserError.noText
        }
        return output
    }
}
