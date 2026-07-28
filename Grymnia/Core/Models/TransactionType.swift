import Foundation

enum TransactionType: String, CaseIterable, Codable {
    case expense
    case income
    case internalTransfer
    case fee
    case hold
    case refund

    var title: String {
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

enum TransactionStatus: String, CaseIterable, Codable {
    case booked
    case pending
}
