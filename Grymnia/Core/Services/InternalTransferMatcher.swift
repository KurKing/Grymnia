import Foundation

enum InternalTransferMatcher {
    static func matches(in transactions: [NormalizedTransaction]) -> [TransferMatch] {
        var result: [TransferMatch] = []
        let candidates = transactions.filter { $0.type == .expense || $0.type == .income }

        for firstIndex in candidates.indices {
            for secondIndex in candidates.index(after: firstIndex)..<candidates.endIndex {
                let first = candidates[firstIndex]
                let second = candidates[secondIndex]
                guard first.currency == second.currency else { continue }
                guard first.accountID != second.accountID else { continue }
                guard (first.amount < 0) != (second.amount < 0) else { continue }
                guard abs(first.amount) == abs(second.amount) else { continue }
                guard abs(first.operationDate.timeIntervalSince(second.operationDate)) <= 3 * 24 * 60 * 60 else { continue }

                let confidence: TransferMatch.Confidence = isTransferLike(first) && isTransferLike(second) ? .high : .ambiguous
                let outgoing = first.amount < 0 ? first : second
                let incoming = first.amount > 0 ? first : second
                result.append(
                    TransferMatch(
                        outgoingID: outgoing.id,
                        incomingID: incoming.id,
                        amount: abs(outgoing.amount),
                        currency: outgoing.currency,
                        confidence: confidence
                    )
                )
            }
        }

        return result
    }

    private static func isTransferLike(_ transaction: NormalizedTransaction) -> Bool {
        let key = MerchantNormalizer.key(transaction.rawDescription + " " + transaction.merchant)
        return key.contains("TRANSFER")
            || key.contains("POPOVN")
            || key.contains("ПЕРЕКАЗ")
            || key.contains("ПОПОВН")
            || key.contains("VID")
            || key.contains("FROM")
            || key.contains("ЗБІЛОЇКАРТКИ")
    }
}
