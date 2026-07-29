import Foundation
import GrymniaStatementParser

extension [NormalizedTransaction] {
    var realExpenses: [NormalizedTransaction] {
        filter { $0.amount < 0 && $0.type != .internalTransfer && $0.type != .hold }
    }

    var expenseTotal: Decimal {
        realExpenses.map(\.amount).reduce(0, +)
    }

    var currentMonthExpenseTotal: Decimal {
        let calendar = Calendar.current
        return realExpenses
            .filter { calendar.isDate($0.operationDate, equalTo: Date(), toGranularity: .month) }
            .map(\.amount)
            .reduce(0, +)
    }
}

extension Decimal {
    var currencyText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "UAH"
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "\(self)"
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
