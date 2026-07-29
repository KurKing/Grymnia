import GrymniaStatementParser
import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var store: GrymniaStore
    @State private var searchText = ""
    @State private var isAddCashPresented = false

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
                        EmptyState(emoji: "₴", title: "No transactions yet.", message: "Import a statement or add a cash expense.")
                        HStack(spacing: 12) {
                            ImportButton()
                            addCashButton
                        }
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

                        HStack(spacing: 12) {
                            ImportButton()
                            addCashButton
                        }
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
        .scrollBounceBehavior(.basedOnSize)
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
        .sheet(isPresented: $isAddCashPresented) {
            ManualCashTransactionView()
                .environmentObject(store)
        }
    }

    private var addCashButton: some View {
        Button {
            isAddCashPresented = true
        } label: {
            Label("Add Cash", systemImage: "plus")
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

private struct ManualCashTransactionView: View {
    @EnvironmentObject private var store: GrymniaStore
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var merchant = ""
    @State private var date = Date()
    @State private var category: TransactionCategory = .other

    private let expenseCategories = TransactionCategory.allCases.filter {
        $0 != .income && $0 != .transfers && $0 != .fees
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Merchant or description", text: $merchant)
                        .textInputAutocapitalization(.words)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(expenseCategories) { category in
                            Text(category.displayTitle)
                                .tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Add Cash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount else { return }
                        store.saveManualCashExpense(
                            amount: amount,
                            date: date,
                            merchant: merchant,
                            category: category
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        amount != nil && !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var amount: Decimal? {
        let normalized = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^\d+(\.\d{1,2})?$"#, options: .regularExpression) != nil else {
            return nil
        }
        guard let decimal = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")),
              decimal > 0 else {
            return nil
        }
        return decimal
    }
}
