import Foundation

public struct TransferMatch: Identifiable, Hashable, Sendable {
    public enum Confidence: String, Sendable {
        case high
        case ambiguous
    }

    public var id: String { [outgoingID, incomingID].sorted().joined(separator: ":") }
    public var outgoingID: String
    public var incomingID: String
    public var amount: Decimal
    public var currency: String
    public var confidence: Confidence

    public init(
        outgoingID: String,
        incomingID: String,
        amount: Decimal,
        currency: String,
        confidence: Confidence
    ) {
        self.outgoingID = outgoingID
        self.incomingID = incomingID
        self.amount = amount
        self.currency = currency
        self.confidence = confidence
    }
}
