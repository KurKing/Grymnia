import Foundation
import PDFKit

public struct MonobankParser: BankStatementParser {
    public init() {}

    public func canParse(_ text: String) -> Bool {
        let latinKey = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).uppercased()
        let ukrainianKey = text.uppercased()
        let monobankBrand = latinKey.contains("MONOBANK")
            || ukrainianKey.contains("МОНОБАНК")
            || ukrainianKey.contains("БІЛОЇ КАРТКИ")
        let universalBankCardStatement = ukrainianKey.contains("УНІВЕРСАЛ БАНК")
            && ukrainianKey.contains("РУХ КОШТІВ ПО КАРТЦІ")
            && ukrainianKey.contains("ДЕТАЛІ ОПЕРАЦІЇ")
            && ukrainianKey.contains("MCC")
            && ukrainianKey.contains("ЗАЛИШОК")
        return monobankBrand || universalBankCardStatement
    }

    public func parse(_ pdf: PDFDocument) throws -> StatementImport {
        try parse(text: visualText(from: pdf))
    }

    public func parse(text: String) throws -> StatementImport {
        let accountID = "monobank-uah"
        let accountAlias = "Monobank • UAH"
        let cardSuffix = firstCardSuffix(in: text)
        let drafts = uniqueDrafts(parseBlocks(
            text,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: cardSuffix
        ) + parseColumnPages(
            text,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: cardSuffix
        ))

        guard !drafts.isEmpty else { throw ParserError.noTransactions(bank: .monobank) }

        let indexes = ParsingHelpers.occurrenceIndexes(for: drafts)
        let transactions = zip(drafts, indexes).map { $0.normalized(occurrenceIndex: $1) }
        return StatementImport(bank: .monobank, accountID: accountID, accountAlias: accountAlias, transactions: transactions)
    }

    private struct RowHeader {
        var date: String
        var time: String
        var merchant: String
        var mcc: Int?
    }

    private struct AmountColumns {
        var cardAmount: Decimal
        var operationAmount: Decimal
        var operationCurrency: String
        var exchangeRate: Decimal?
        var fee: Decimal?
        var cashback: Decimal?
        var balanceAfter: Decimal?
    }

    private let amountPattern = #"[+-]?\s*\d[\d\s]*(?:[,.]\d{2})?"#

    private func parseBlocks(
        _ text: String,
        accountID: String,
        accountAlias: String,
        cardSuffix: String?
    ) -> [ParsedTransactionDraft] {
        var blocks: [[String]] = []
        var currentLines: [String] = []

        func flush() {
            guard !currentLines.isEmpty else { return }
            blocks.append(currentLines)
            currentLines = []
        }

        for line in text.components(separatedBy: .newlines) {
            let compact = line
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !compact.isEmpty else { continue }
            if isTableHeader(compact) {
                if isFooter(compact) {
                    flush()
                }
                continue
            }

            if compact.range(of: #"^\d{2}\.\d{2}\.\d{4}\b"#, options: .regularExpression) != nil {
                flush()
                currentLines = [compact]
            } else if !currentLines.isEmpty {
                currentLines.append(compact)
            }
        }
        flush()

        let parsed = blocks.compactMap {
            parseBlock(
                $0,
                accountID: accountID,
                accountAlias: accountAlias,
                cardSuffix: cardSuffix
            )
        }

        if parsed.isEmpty {
            return text
                .components(separatedBy: .newlines)
                .compactMap { parseLine($0, accountID: accountID, accountAlias: accountAlias, fallbackCardSuffix: cardSuffix) }
        }
        return parsed
    }

    private func parseColumnPages(
        _ text: String,
        accountID: String,
        accountAlias: String,
        cardSuffix: String?
    ) -> [ParsedTransactionDraft] {
        text
            .components(separatedBy: "\u{000c}")
            .flatMap { page -> [ParsedTransactionDraft] in
                let lines = normalizedLines(page)
                let amounts = amountColumns(in: lines)
                let headers = rowHeaders(in: lines, expectedCount: amounts.count)
                guard !headers.isEmpty, headers.count == amounts.count else { return [] }

                return zip(headers, amounts).compactMap { header, amount in
                    guard let date = date(date: header.date, time: header.time) else { return nil }
                    let isForeignCurrency = amount.operationCurrency != "UAH"
                    let type = ParsingHelpers.transactionType(amount: amount.cardAmount, rawDescription: header.merchant)
                    return ParsedTransactionDraft(
                        bank: .monobank,
                        accountID: accountID,
                        accountAlias: accountAlias,
                        cardSuffix: cardSuffix,
                        operationDate: date,
                        postingDate: nil,
                        merchant: header.merchant,
                        rawDescription: [
                            header.date,
                            header.time,
                            header.merchant,
                            header.mcc.map(String.init) ?? "",
                            NSDecimalNumber(decimal: amount.cardAmount).stringValue,
                            amount.operationCurrency
                        ].filter { !$0.isEmpty }.joined(separator: " "),
                        mcc: header.mcc,
                        amount: amount.cardAmount,
                        currency: "UAH",
                        originalAmount: isForeignCurrency ? amount.operationAmount : nil,
                        originalCurrency: isForeignCurrency ? amount.operationCurrency : nil,
                        exchangeRate: amount.exchangeRate,
                        cashback: amount.cashback,
                        fee: amount.fee == 0 ? nil : amount.fee,
                        balanceAfter: amount.balanceAfter,
                        type: type,
                        status: .booked
                    )
                }
            }
    }

    private func rowHeaders(in lines: [String], expectedCount: Int) -> [RowHeader] {
        let sequential = sequentialRowHeaders(in: lines)
        if !sequential.isEmpty, sequential.count == expectedCount {
            return sequential
        }
        return columnRowHeaders(in: lines)
    }

    private func sequentialRowHeaders(in lines: [String]) -> [RowHeader] {
        var output: [RowHeader] = []
        var index = 0
        while index < lines.count {
            guard isDate(lines[index]),
                  index + 1 < lines.count,
                  isTime(lines[index + 1]) else {
                index += 1
                continue
            }

            let date = lines[index]
            let time = lines[index + 1]
            index += 2
            var merchantParts: [String] = []
            var mcc: Int?

            while index < lines.count {
                let line = lines[index]
                if isDate(line) || line.contains("Сума в") {
                    break
                }
                if let parsed = mccOnly(line) {
                    mcc = parsed
                    index += 1
                    break
                }
                if let match = match(#"^(?<merchant>.+?)\s+(?<mcc>\d{3,4})(?:\s|$)"#, in: line),
                   let parsed = Int(match["mcc"] ?? "") {
                    merchantParts.append(match["merchant"] ?? "")
                    mcc = parsed
                    index += 1
                    break
                }
                if !isTableHeader(line) {
                    merchantParts.append(line)
                }
                index += 1
            }

            if let mcc, !merchantParts.isEmpty {
                output.append(RowHeader(date: date, time: time, merchant: merchantParts.joined(separator: " "), mcc: mcc))
            }
        }
        return output
    }

    private func columnRowHeaders(in lines: [String]) -> [RowHeader] {
        guard let detailsIndex = lines.firstIndex(where: { $0.contains("Деталі операції") }),
              let mccIndex = lines[detailsIndex...].firstIndex(where: { $0 == "MCC" || $0.hasPrefix("MCC ") }) else {
            return []
        }

        let dates = dateTimes(in: Array(lines[..<detailsIndex]))
        let detailLines = Array(lines[(detailsIndex + 1)..<mccIndex])
        let mccs = mccValues(in: Array(lines[(mccIndex + 1)...]))
        let merchants = collapsedMerchants(detailLines, targetCount: min(dates.count, mccs.count))
        let count = min(dates.count, merchants.count, mccs.count)

        return (0..<count).map { index in
            RowHeader(
                date: dates[index].date,
                time: dates[index].time,
                merchant: merchants[index],
                mcc: mccs[index]
            )
        }
    }

    private func amountColumns(in lines: [String]) -> [AmountColumns] {
        let text = lines.joined(separator: " ")
        let marker = "валюті операції"
        let searchText: String
        if let range = text.range(of: marker) {
            searchText = String(text[range.upperBound...])
        } else {
            searchText = text
        }

        let pattern = #"(?<operationAmount>"# + amountPattern + #")\s+(?<currency>UAH|USD|EUR|грн)\s+(?<rate>—|"# + amountPattern + #")\s+(?<fee>"# + amountPattern + #")\s+(?<cashback>"# + amountPattern + #")\s+(?<balance>"# + amountPattern + #")"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }

        let cardAmounts = cardAmounts(in: text)
        guard !cardAmounts.isEmpty else {
            return []
        }

        let range = NSRange(searchText.startIndex..<searchText.endIndex, in: searchText)
        let operationColumns = regex.matches(in: searchText, range: range).compactMap { result -> AmountColumns? in
            guard let operationAmount = ParsingHelpers.decimal(from: group("operationAmount", in: searchText, result: result)) else {
                return nil
            }
            let currency = normalizedCurrency(group("currency", in: searchText, result: result), fallback: "UAH")
            return AmountColumns(
                cardAmount: operationAmount,
                operationAmount: operationAmount,
                operationCurrency: currency,
                exchangeRate: ParsingHelpers.decimal(from: group("rate", in: searchText, result: result)),
                fee: ParsingHelpers.decimal(from: group("fee", in: searchText, result: result)),
                cashback: ParsingHelpers.decimal(from: group("cashback", in: searchText, result: result)),
                balanceAfter: ParsingHelpers.decimal(from: group("balance", in: searchText, result: result))
            )
        }

        guard cardAmounts.count == operationColumns.count else { return [] }

        return zip(cardAmounts, operationColumns).map { cardAmount, columns in
            AmountColumns(
                cardAmount: cardAmount,
                operationAmount: columns.operationAmount,
                operationCurrency: columns.operationCurrency,
                exchangeRate: columns.exchangeRate,
                fee: columns.fee,
                cashback: columns.cashback,
                balanceAfter: columns.balanceAfter
            )
        }
    }

    private func cardAmounts(in text: String) -> [Decimal] {
        guard let first = text.range(of: "(UAH)"),
              let second = text[first.upperBound...].range(of: "Сума в") else {
            return []
        }
        return decimals(in: String(text[first.upperBound..<second.lowerBound]))
    }

    private func dateTimes(in lines: [String]) -> [(date: String, time: String)] {
        var output: [(String, String)] = []
        var index = 0
        while index + 1 < lines.count {
            if isDate(lines[index]), isTime(lines[index + 1]) {
                output.append((lines[index], lines[index + 1]))
                index += 2
            } else {
                index += 1
            }
        }
        return output
    }

    private func collapsedMerchants(_ lines: [String], targetCount: Int) -> [String] {
        var merchants = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        while merchants.count > targetCount, let index = continuationIndex(in: merchants) {
            merchants[index - 1] += " " + merchants[index]
            merchants.remove(at: index)
        }
        return merchants
    }

    private func continuationIndex(in merchants: [String]) -> Int? {
        merchants.indices.dropFirst().first { index in
            let line = merchants[index]
            let previous = merchants[index - 1]
            return line.hasPrefix("+")
                || line.hasPrefix("«")
                || line.first?.isLowercase == true
                || previous.hasPrefix("Поповнення")
                || previous.hasPrefix("Від:")
                || previous.hasPrefix("ФОП")
                || previous.hasPrefix("ТОВ")
                || previous == "PETCUBE"
                || previous == "Щомісячний платіж"
        }
    }

    private func mccValues(in lines: [String]) -> [Int] {
        lines.prefix { !$0.contains("Сума в") }
            .compactMap { mccOnly($0) }
    }

    private func mccOnly(_ line: String) -> Int? {
        guard line.range(of: #"^\d{3,4}$"#, options: .regularExpression) != nil else {
            return nil
        }
        return Int(line)
    }

    private func decimals(in text: String) -> [Decimal] {
        guard let regex = try? NSRegularExpression(pattern: amountPattern) else {
            return []
        }
        return regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
            .compactMap { result in
                guard let range = Range(result.range, in: text) else { return nil }
                return ParsingHelpers.decimal(from: String(text[range]))
            }
    }

    private func isDate(_ line: String) -> Bool {
        line.range(of: #"^\d{2}\.\d{2}\.\d{4}$"#, options: .regularExpression) != nil
    }

    private func isTime(_ line: String) -> Bool {
        line.range(of: #"^\d{2}:\d{2}(?::\d{2})?$"#, options: .regularExpression) != nil
    }

    private func normalizedLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines).map {
            $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
    }

    private func uniqueDrafts(_ drafts: [ParsedTransactionDraft]) -> [ParsedTransactionDraft] {
        var seen: Set<String> = []
        return drafts.filter { draft in
            let key = [
                draft.accountID,
                NSDecimalNumber(decimal: draft.amount).stringValue,
                draft.currency,
                draft.mcc.map(String.init) ?? "",
                draft.merchant,
                ISO8601DateFormatter().string(from: draft.operationDate)
            ].joined(separator: "|")
            return seen.insert(key).inserted
        }
    }

    private func parseBlock(
        _ lines: [String],
        accountID: String,
        accountAlias: String,
        cardSuffix: String?
    ) -> ParsedTransactionDraft? {
        let compact = lines.joined(separator: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let pattern = #"^(?<date>\d{2}\.\d{2}\.\d{4})(?:\s+(?<time>\d{2}:\d{2}(?::\d{2})?))?\s+(?<merchant>.*?)\s+(?<mcc>\d{3,4})\s+(?<amount>"# + amountPattern + #")\s+(?<originalAmount>"# + amountPattern + #")\s+(?<currency>UAH|USD|EUR|грн)\s+(?<rate>—|"# + amountPattern + #")\s+(?<fee>"# + amountPattern + #")\s+(?<cashback>"# + amountPattern + #")\s+(?<balance>"# + amountPattern + #")(?<tail>.*)$"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let result = regex.firstMatch(in: compact, range: NSRange(compact.startIndex..<compact.endIndex, in: compact)),
              let date = date(
                date: group("date", in: compact, result: result),
                time: group("time", in: compact, result: result)
              ),
              let amount = ParsingHelpers.decimal(from: group("amount", in: compact, result: result)) else {
            return nil
        }

        let currency = normalizedCurrency(group("currency", in: compact, result: result), fallback: "UAH")
        let originalAmount = ParsingHelpers.decimal(from: group("originalAmount", in: compact, result: result))
        let originalCurrency = currency == "UAH" ? nil : currency
        let rawMerchant = merchant(
            leading: group("merchant", in: compact, result: result),
            tail: group("tail", in: compact, result: result)
        )
        let fee = ParsingHelpers.decimal(from: group("fee", in: compact, result: result))
        let type = ParsingHelpers.transactionType(amount: amount, rawDescription: compact)

        return ParsedTransactionDraft(
            bank: .monobank,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: cardSuffix,
            operationDate: date,
            postingDate: nil,
            merchant: rawMerchant,
            rawDescription: compact,
            mcc: Int(group("mcc", in: compact, result: result)),
            amount: amount,
            currency: "UAH",
            originalAmount: originalCurrency == nil ? nil : originalAmount,
            originalCurrency: originalCurrency,
            exchangeRate: ParsingHelpers.decimal(from: group("rate", in: compact, result: result)),
            cashback: ParsingHelpers.decimal(from: group("cashback", in: compact, result: result)),
            fee: fee == 0 ? nil : fee,
            balanceAfter: ParsingHelpers.decimal(from: group("balance", in: compact, result: result)),
            type: type,
            status: .booked
        )
    }

    private func parseLine(_ line: String, accountID: String, accountAlias: String) -> ParsedTransactionDraft? {
        parseLine(line, accountID: accountID, accountAlias: accountAlias, fallbackCardSuffix: nil)
    }

    private func parseLine(_ line: String, accountID: String, accountAlias: String, fallbackCardSuffix: String?) -> ParsedTransactionDraft? {
        let compact = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        guard compact.range(of: #"\d{2}\.\d{2}\.\d{4}"#, options: .regularExpression) != nil else { return nil }

        let pattern = #"(?<date>\d{2}\.\d{2}\.\d{4}(?:\s+\d{2}:\d{2}(?::\d{2})?)?)\s+(?<merchant>.*?)(?:\s+\[(?<mcc>\d{3,4})\])?.*?(?<amount>[+-]\s*\d[\d\s]*(?:[,.]\d{2})?)\s*(?<currency>UAH|USD|EUR|грн)"#
        guard let match = match(pattern, in: compact),
              let date = ParsingHelpers.date(match["date"] ?? ""),
              let amount = ParsingHelpers.decimal(from: match["amount"] ?? "") else {
            return nil
        }

        let merchant = (match["merchant"] ?? "Unknown merchant")
            .replacingOccurrences(of: #"(?i)\b(MCC|UAH|USD|EUR|грн)\b"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let currency = normalizedCurrency(match["currency"], fallback: "UAH")
        let type = ParsingHelpers.transactionType(amount: amount, rawDescription: compact)

        return ParsedTransactionDraft(
            bank: .monobank,
            accountID: accountID,
            accountAlias: accountAlias,
            cardSuffix: cardSuffix(in: compact) ?? fallbackCardSuffix,
            operationDate: date,
            postingDate: nil,
            merchant: merchant,
            rawDescription: compact,
            mcc: Int(match["mcc"] ?? ""),
            amount: amount,
            currency: currency,
            originalAmount: originalAmount(in: compact),
            originalCurrency: originalCurrency(in: compact),
            exchangeRate: decimal(after: #"курс[:\s]+"#, in: compact),
            cashback: decimal(after: #"кешбек[:\s]+"#, in: compact),
            fee: decimal(after: #"комісія[:\s]+"#, in: compact),
            balanceAfter: decimal(after: #"залишок[:\s]+"#, in: compact),
            type: type,
            status: .booked
        )
    }

    private func date(date rawDate: String, time rawTime: String) -> Date? {
        if !rawTime.isEmpty, let date = ParsingHelpers.date(rawDate + " " + rawTime) {
            return date
        }
        return ParsingHelpers.date(rawDate)
    }

    private func group(_ name: String, in value: String, result: NSTextCheckingResult) -> String {
        let range = result.range(withName: name)
        guard range.location != NSNotFound, let swiftRange = Range(range, in: value) else {
            return ""
        }
        return String(value[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func merchant(leading: String, tail: String) -> String {
        let detail = tail
            .replacingOccurrences(of: #"\b\d{2}:\d{2}:\d{2}\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\s*\d{2}:\d{2}\b"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = [leading, detail]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .replacingOccurrences(of: #"(?i)\b(UAH|USD|EUR|грн)\b"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return combined.isEmpty ? "Unknown merchant" : combined
    }

    private func isTableHeader(_ line: String) -> Bool {
        line.contains("Сума в")
            || line.contains("Дата i час")
            || line == "операції"
            || line == "(UAH)"
            || isFooter(line)
    }

    private func isFooter(_ line: String) -> Bool {
        line.contains("Операційний директор")
            || line.contains("Документ підписано")
            || line.contains("Вклади гарантуються")
            || line.contains("Для перевірки підпису")
            || line.contains("Як скористатись сервісом")
    }

    private func firstCardSuffix(in text: String) -> String? {
        match(#"\*{4}\s+(?<suffix>\d{4})"#, in: text)?["suffix"]
    }

    private func visualText(from document: PDFDocument) throws -> String {
        var pages: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let pageBounds = page.bounds(for: .mediaBox)
            let lines = page.selection(for: pageBounds)?
                .selectionsByLine()
                .compactMap { $0.string }
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
            if !lines.isEmpty {
                pages.append(lines.joined(separator: "\n"))
            } else if let text = page.string, !text.isEmpty {
                pages.append(text)
            }
        }

        let output = pages.joined(separator: "\n\u{000c}\n")
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParserError.noText
        }
        return output
    }

    private func cardSuffix(in line: String) -> String? {
        match(#"\*(?<suffix>\d{4})"#, in: line)?["suffix"]
    }

    private func originalAmount(in line: String) -> Decimal? {
        decimal(after: #"оригінальна\s+сума[:\s]+"#, in: line)
    }

    private func originalCurrency(in line: String) -> String? {
        match(#"(?i)оригінальна\s+валюта[:\s]+(?<currency>UAH|USD|EUR|PLN|GBP)"#, in: line)?["currency"]?.uppercased()
    }

    private func decimal(after prefix: String, in line: String) -> Decimal? {
        guard let value = match(prefix + #"(?<value>[+-]?\s*\d[\d\s]*(?:[,.]\d{2,6})?)"#, in: line)?["value"] else {
            return nil
        }
        return ParsingHelpers.decimal(from: value)
    }
}
