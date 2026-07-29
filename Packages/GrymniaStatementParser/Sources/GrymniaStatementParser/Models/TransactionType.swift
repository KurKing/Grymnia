import Foundation

public enum TransactionType: String, CaseIterable, Codable, Sendable {
    case expense
    case income
    case internalTransfer
    case fee
    case hold
    case refund

    public var title: String {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        case .internalTransfer: "Internal Transfer"
        case .fee: "Fee"
        case .hold: "Hold"
        case .refund: "Refund"
        }
    }
}

public enum TransactionStatus: String, CaseIterable, Codable, Sendable {
    case booked
    case pending
}
