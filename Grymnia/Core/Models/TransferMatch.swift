import Foundation

struct TransferMatch: Identifiable, Hashable {
    enum Confidence: String {
        case high
        case ambiguous
    }

    var id: String { [outgoingID, incomingID].sorted().joined(separator: ":") }
    var outgoingID: String
    var incomingID: String
    var amount: Decimal
    var currency: String
    var confidence: Confidence
}
