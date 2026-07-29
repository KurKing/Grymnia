import GrymniaStatementParser
import SwiftUI

struct TransactionRow: View {
    let transaction: NormalizedTransaction

    var body: some View {
        HStack(spacing: 12) {
            Text(transaction.category.emoji)
                .font(.system(size: 30))
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(categoryTint.opacity(0.14))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                Text("\(transaction.category.title) • \(transaction.bank.displayName)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(GrymniaDesign.secondaryText)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amount.currencyText)
                    .font(.system(.body, design: .rounded).monospacedDigit().weight(.semibold))
                    .foregroundStyle(transaction.amount < 0 ? GrymniaDesign.expense : GrymniaDesign.success)
                Text(transaction.operationDate, format: .dateTime.day().month().year())
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(GrymniaDesign.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }

    private var categoryTint: Color {
        switch transaction.category {
        case .income:
            GrymniaDesign.success
        case .transfers:
            GrymniaDesign.primary
        case .fees:
            GrymniaDesign.warning
        default:
            GrymniaDesign.accent
        }
    }
}
