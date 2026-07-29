import Foundation
import PDFKit

public struct CreditAgricoleParser: BankStatementParser {
    public init() {}

    public func canParse(_ text: String) -> Bool {
        let key = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).uppercased()
        return key.contains("CREDIT AGRICOLE")
            || key.contains("CRÉDIT AGRICOLE")
            || key.contains("КРЕДІ АГРІКОЛЬ")
            || (key.contains("[5411]") && key.contains("SILPO"))
    }

    public func parse(_ pdf: PDFDocument) throws -> StatementImport {
        try parse(text: PDFTextExtractor.text(from: pdf))
    }

    public func parse(text: String) throws -> StatementImport {
        let accountID = "credit-agricole-uah"
        let accountAlias = "Credit Agricole • UAH"
        let cardSuffixes = cardSuffixesByIndex(in: text)
        let drafts = parseBlocks(
            text,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffixes: cardSuffixes
        )

        guard !drafts.isEmpty else { throw ParserError.noTransactions(bank: .creditAgricole) }

        let indexes = ParsingHelpers.occurrenceIndexes(for: drafts)
        let transactions = zip(drafts, indexes).map { $0.normalized(occurrenceIndex: $1) }
        return StatementImport(
            bank: .creditAgricole,
            accountID: accountID,
            accountAlias: accountAlias,
            transactions: transactions
        )
    }

    private struct StatementRow {
        var cardIndex: String?
        var operationDate: Date
        var postingDate: Date?
        var isHold: Bool
    }

    private struct StatementAmount {
        var operationAmount: Decimal
        var accountAmount: Decimal?
        var operationCurrency: String
    }

    private let amountPattern = #"[+-]?\s*\d[\d\s]*(?:[,.]\d{2})?"#

    private func parseBlocks(
        _ text: String,
        accountID: String,
        accountAlias: String,
        cardSuffixes: [String: String]
    ) -> [ParsedTransactionDraft] {
        var blocks: [(row: StatementRow, lines: [String])] = []
        var currentRow: StatementRow?
        var currentLines: [String] = []
        var isHoldSection = false

        func flush() {
            guard let row = currentRow else { return }
            blocks.append((row, currentLines))
            currentRow = nil
            currentLines = []
        }

        for line in text.components(separatedBy: .newlines) {
            let compact = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !compact.isEmpty else { continue }
            if dateCount(in: compact) > 8 {
                flush()
                continue
            }

            if compact.contains("Блокування за рахунком") {
                flush()
                isHoldSection = true
                continue
            }
            if compact.contains("Баланс рахунків на кінцеву дату")
                || compact.contains("Всього блокувань")
                || compact.contains("Всього по внутрішнім операціям")
                || compact.contains("Всього по видатковим операціям") {
                flush()
                continue
            }

            if var row = parseRow(compact) {
                flush()
                row.isHold = isHoldSection
                currentRow = row
                currentLines = [compact]
            } else if currentRow != nil {
                currentLines.append(compact)
            }
        }
        flush()

        let parsed = blocks.compactMap {
            parseBlock(
                row: $0.row,
                lines: $0.lines,
                accountID: accountID,
                accountAlias: accountAlias,
                cardSuffixes: cardSuffixes
            )
        }

        if parsed.isEmpty {
            return text
                .components(separatedBy: .newlines)
                .compactMap { parseLine($0, accountID: accountID, accountAlias: accountAlias) }
        }
        return parsed
    }

    private func dateCount(in line: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: #"\d{2}\.\d{2}\.\d{4}"#) else {
            return 0
        }
        return regex.numberOfMatches(in: line, range: NSRange(line.startIndex..<line.endIndex, in: line))
    }

    private func parseRow(_ line: String) -> StatementRow? {
        let pattern = #"^\s*(?:(\d{1,2})\s+)?(\d{2}\.\d{2}\.\d{4})\s+(\d{2}\.\d{2}\.\d{4})(?:\s+\d{0,7})?(?:\s+.*)?$"#
        guard let groups = captureGroups(pattern, in: line),
              let operationDate = ParsingHelpers.date(groups[1]) else {
            return nil
        }

        return StatementRow(
            cardIndex: groups[0].isEmpty ? nil : groups[0],
            operationDate: operationDate,
            postingDate: ParsingHelpers.date(groups[2]),
            isHold: false
        )
    }

    private func parseBlock(
        row: StatementRow,
        lines: [String],
        accountID: String,
        accountAlias: String,
        cardSuffixes: [String: String]
    ) -> ParsedTransactionDraft? {
        let compact = lines.joined(separator: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let statementAmount = amount(in: compact) else { return nil }

        let mcc = match(#"\[(?<mcc>\d{3,4})\]"#, in: compact)?["mcc"].flatMap(Int.init)
        let merchant = merchant(in: compact) ?? operationDescription(in: compact)
        guard let merchant else { return nil }

        let accountCurrency = "UAH"
        let isForeignCurrency = statementAmount.operationCurrency != accountCurrency
        let amount = isForeignCurrency ? (statementAmount.accountAmount ?? statementAmount.operationAmount) : (statementAmount.accountAmount ?? statementAmount.operationAmount)
        let currency = isForeignCurrency && statementAmount.accountAmount != nil ? accountCurrency : statementAmount.operationCurrency
        let originalAmount = isForeignCurrency ? statementAmount.operationAmount : nil
        let originalCurrency = isForeignCurrency ? statementAmount.operationCurrency : nil
        let type: TransactionType = row.isHold ? .hold : ParsingHelpers.transactionType(amount: amount, rawDescription: compact)

        return ParsedTransactionDraft(
            bank: .creditAgricole,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: row.cardIndex.flatMap { cardSuffixes[$0] },
            operationDate: row.operationDate,
            postingDate: row.postingDate,
            merchant: merchant,
            rawDescription: compact,
            mcc: mcc,
            amount: amount,
            currency: currency,
            originalAmount: originalAmount,
            originalCurrency: originalCurrency,
            exchangeRate: nil,
            cashback: nil,
            fee: type == .fee ? abs(amount) : nil,
            balanceAfter: nil,
            type: type,
            status: row.isHold ? .pending : .booked
        )
    }

    private func amount(in line: String) -> StatementAmount? {
        let pattern = #"\b(UAH|USD|EUR)\s+("# + amountPattern + #")(?:\s+("# + amountPattern + #"))?\b"#
        guard let groups = captureGroups(pattern, in: line),
              groups.count > 1,
              let operationAmount = ParsingHelpers.decimal(from: groups[1]) else {
            return nil
        }

        return StatementAmount(
            operationAmount: operationAmount,
            accountAmount: groups.count > 2 ? ParsingHelpers.decimal(from: groups[2]) : nil,
            operationCurrency: normalizedCurrency(groups[0], fallback: "UAH")
        )
    }

    private func merchant(in line: String) -> String? {
        guard let groups = captureGroups(#"\[(\d{3,4})\],?\s*(.*?)(?:\s+(?:UAH|USD|EUR)\s+[+-]|\s+0000000\s+| Всього| Баланс|$)"#, in: line),
              groups.count > 1 else {
            return nil
        }

        let merchant = groups[1]
            .replacingOccurrences(of: #"(?i)\b(UAH|USD|EUR|грн)\b"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ","))
        return merchant.isEmpty ? nil : merchant
    }

    private func operationDescription(in line: String) -> String? {
        let descriptions = [
            "Погашення конвертаційних витрат",
            "Плата за конвертацію валют при оплаті товарів/послуг",
            "Поповнення рахунку"
        ]
        return descriptions.first { line.contains($0) }
    }

    private func cardSuffixesByIndex(in text: String) -> [String: String] {
        var output: [String: String] = [:]
        let pattern = #"\((\d+)\).*?\*{4}\s+(\d{4})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return output
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for result in regex.matches(in: text, range: range) {
            guard let indexRange = Range(result.range(at: 1), in: text),
                  let suffixRange = Range(result.range(at: 2), in: text) else {
                continue
            }
            output[String(text[indexRange])] = String(text[suffixRange])
        }
        return output
    }

    private func captureGroups(_ pattern: String, in value: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let result = regex.firstMatch(in: value, range: range) else {
            return nil
        }
        return (1..<result.numberOfRanges).map { index in
            guard result.range(at: index).location != NSNotFound,
                  let swiftRange = Range(result.range(at: index), in: value) else {
                return ""
            }
            return String(value[swiftRange])
        }
    }

    private func parseLine(_ line: String, accountID: String, accountAlias: String) -> ParsedTransactionDraft? {
        let compact = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard compact.contains("[") else { return nil }

        let pattern = #"(?<operation>\d{2}\.\d{2}\.\d{4})(?:\s+(?<posting>\d{2}\.\d{2}\.\d{4}))?.*?\[(?<mcc>\d{3,4})\],?\s*(?<merchant>.*?)(?:\s{2,}|;|\|).*(?<amount>"# + amountPattern + #")\s*(?<currency>UAH|USD|EUR|грн)?"#
        guard let match = match(pattern, in: compact),
              let operationDate = ParsingHelpers.date(match["operation"] ?? ""),
              let amount = ParsingHelpers.decimal(from: match["amount"] ?? "") else {
            return nil
        }

        let rawMerchant = (match["merchant"] ?? "Unknown merchant")
            .replacingOccurrences(of: #"(?i)\b(UAH|USD|EUR|грн)\b"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let mcc = Int(match["mcc"] ?? "")
        let postingDate = (match["posting"] ?? "").isEmpty ? nil : ParsingHelpers.date(match["posting"] ?? "")
        let currency = normalizedCurrency(match["currency"], fallback: "UAH")
        let type = ParsingHelpers.transactionType(amount: amount, rawDescription: compact)

        return ParsedTransactionDraft(
            bank: .creditAgricole,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: cardSuffix(in: compact),
            operationDate: operationDate,
            postingDate: postingDate,
            merchant: rawMerchant,
            rawDescription: compact,
            mcc: mcc,
            amount: amount,
            currency: currency,
            originalAmount: nil,
            originalCurrency: nil,
            exchangeRate: nil,
            cashback: nil,
            fee: type == .fee ? abs(amount) : nil,
            balanceAfter: nil,
            type: type,
            status: type == .hold ? .pending : .booked
        )
    }

    private func cardSuffix(in line: String) -> String? {
        guard let match = match(#"(?:картк[аи]|card)\s*(?:№|#)?\s*(?<suffix>\d{1,4})"#, in: line) else {
            return nil
        }
        return match["suffix"]
    }
}
