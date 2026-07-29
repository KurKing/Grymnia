import GrymniaStatementParser
import SwiftUI

struct ImportPreviewView: View {
    @EnvironmentObject private var store: GrymniaStore

    var body: some View {
        ScrollView {
            if let pendingImport = store.pendingImport {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("✨ \(pendingImport.transactions.count) transactions found")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                        Text("\(pendingImport.bank.displayName) • \(pendingImport.accountAlias)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(GrymniaDesign.secondaryText)

                        HStack(spacing: 10) {
                            ImportStep(emoji: "📥", title: "Choose PDF", isActive: false)
                            ImportStep(emoji: "🔍", title: "Parsed", isActive: false)
                            ImportStep(emoji: "✅", title: "Review", isActive: true)
                        }
                    }
                    .grymniaCard()

                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(emoji: "🏦", title: "Bank", value: pendingImport.bank.displayName)
                        InfoRow(emoji: "💳", title: "Account", value: pendingImport.accountAlias)
                        InfoRow(emoji: "📊", title: "Total spend", value: pendingImport.transactions.expenseTotal.currencyText)
                    }
                    .grymniaCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("📝 Preview")
                            .font(.system(.title3, design: .rounded).weight(.semibold))

                        ForEach(pendingImport.transactions.prefix(40)) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .grymniaCard()
                }
                .padding(20)
            }
        }
        .background(GrymniaDesign.background)
        .navigationTitle("Import")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    store.cancelPendingImport()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("✅ Save") {
                    store.savePendingImport()
                }
                .disabled(store.pendingImport?.transactions.isEmpty ?? true)
            }
        }
    }
}

private struct ImportStep: View {
    let emoji: String
    let title: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 28))
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(isActive ? GrymniaDesign.primary : GrymniaDesign.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isActive ? GrymniaDesign.primary.opacity(0.12) : Color.secondary.opacity(0.08))
        }
    }
}

private struct InfoRow: View {
    let emoji: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title3)
            Text(title)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(GrymniaDesign.secondaryText)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }
}
