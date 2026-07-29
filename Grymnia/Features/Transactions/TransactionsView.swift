import GrymniaStatementParser
import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: GrymniaStore
    @State private var searchText = ""

    var filteredTransactions: [NormalizedTransaction] {
        guard !searchText.isEmpty else { return store.transactions }
        return store.transactions.filter {
            $0.merchant.localizedCaseInsensitiveContains(searchText)
                || $0.rawDescription.localizedCaseInsensitiveContains(searchText)
                || $0.category.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if store.transactions.isEmpty {
                    VStack(spacing: 18) {
                        EmptyState(emoji: "🪙", title: "No transactions yet.", message: "Import your first statement.")
                        ImportButton()
                    }
                    .grymniaCard()
                    .padding(.top, 24)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📝 Transactions")
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                            Text("\(filteredTransactions.count) items")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(GrymniaDesign.secondaryText)
                        }

                        Spacer()

                        ImportButton()
                    }
                    .grymniaCard()

                    VStack(spacing: 0) {
                        ForEach(filteredTransactions) { transaction in
                            TransactionRow(transaction: transaction)
                            if transaction.id != filteredTransactions.last?.id {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .grymniaCard()
                }
            }
            .padding(20)
        }
        .background(GrymniaDesign.background)
        .overlay {
            if store.isImporting {
                VStack(spacing: 12) {
                    Text("🔍")
                        .font(.system(size: 48))
                    Text("Parsing...")
                        .font(.system(.headline, design: .rounded))
                }
                .grymniaCard()
            }
        }
        .navigationTitle("Transactions")
        .searchable(text: $searchText, prompt: "Merchant, category, description")
    }
}
