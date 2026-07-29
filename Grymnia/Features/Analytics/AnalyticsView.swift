import Charts
import GrymniaStatementParser
import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: GrymniaStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                summaryGrid
                categorySection
                recentExpensesSection
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(GrymniaDesign.background)
        .navigationTitle("July")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ImportButton()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Grymnia")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Text("Your money. Your data.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(GrymniaDesign.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .grymniaCard()
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            StatCard(emoji: "📊", title: "Spending", value: currentMonthSpend.currencyText, tint: GrymniaDesign.expense)
            StatCard(emoji: "📈", title: "Monthly trend", value: trendText, tint: GrymniaDesign.accent)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("📊 Spending")
                .font(.system(.title2, design: .rounded).weight(.semibold))

            if categoryTotals.isEmpty {
                EmptyState(emoji: "📥", title: "Import your first statement.", message: "PDFs stay on this iPhone.")
            } else {
                CategoryBreakdownChart(items: Array(categoryTotals.prefix(8)), total: categorySpendTotal)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: categoryTotals.map(\.amount.doubleValue))
            }
        }
        .grymniaCard()
    }

    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💸 Recent expenses")
                .font(.system(.title2, design: .rounded).weight(.semibold))

            if recentExpenses.isEmpty {
                EmptyState(emoji: "₴", title: "No transactions yet.", message: "Import a PDF statement to begin.")
            } else {
                ForEach(recentExpenses) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .grymniaCard()
    }

    private var currentMonthSpend: Decimal {
        abs(store.transactions.currentMonthExpenseTotal)
    }

    private var trendText: String {
        currentMonthSpend == 0 ? "Fresh start" : currentMonthSpend.currencyText
    }

    private var recentExpenses: [NormalizedTransaction] {
        Array(store.transactions.realExpenses.sorted { $0.operationDate > $1.operationDate }.prefix(5))
    }

    private var categoryTotals: [CategoryTotal] {
        Dictionary(grouping: store.transactions.realExpenses, by: \.category)
            .map { CategoryTotal(category: $0.key, amount: abs($0.value.map(\.amount).reduce(0, +))) }
            .sorted { $0.amount > $1.amount }
    }

    private var categorySpendTotal: Decimal {
        categoryTotals.map(\.amount).reduce(0, +)
    }

    private var merchantTotals: [MerchantTotal] {
        Dictionary(grouping: store.transactions.realExpenses, by: \.merchant)
            .map { MerchantTotal(merchant: $0.key, amount: abs($0.value.map(\.amount).reduce(0, +))) }
            .sorted { $0.amount > $1.amount }
    }
}

struct CategoryTotal: Identifiable {
    var id: String { category.rawValue }
    var category: TransactionCategory
    var amount: Decimal
}

struct MerchantTotal: Identifiable {
    var id: String { merchant }
    var merchant: String
    var amount: Decimal
}

private struct CategoryBreakdownChart: View {
    let items: [CategoryTotal]
    let total: Decimal

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Chart(Array(items.enumerated()), id: \.element.id) { index, item in
                    SectorMark(
                        angle: .value("Amount", item.amount.doubleValue),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .cornerRadius(6)
                    .foregroundStyle(color(for: index))
                }
                .chartLegend(.hidden)
                .frame(height: 240)
                .accessibilityLabel("Spending by category")

                VStack(spacing: 4) {
                    Text("Total")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(GrymniaDesign.secondaryText)
                    Text(total.currencyText)
                        .font(.system(.title3, design: .rounded).monospacedDigit().weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
                .frame(width: 130)
            }

            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    CategoryBreakdownRow(
                        item: item,
                        percentage: percentage(for: item),
                        color: color(for: index)
                    )
                }
            }
        }
    }

    private func percentage(for item: CategoryTotal) -> Int {
        guard total > 0 else { return 0 }
        return Int((item.amount.doubleValue / total.doubleValue * 100).rounded())
    }

    private func color(for index: Int) -> Color {
        GrymniaDesign.categoryPastels[index % GrymniaDesign.categoryPastels.count]
    }
}

private struct CategoryBreakdownRow: View {
    let item: CategoryTotal
    let percentage: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(item.category.displayTitle)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.amount.currencyText)
                    .font(.system(.subheadline, design: .rounded).monospacedDigit().weight(.semibold))
                Text("\(percentage)%")
                    .font(.system(.caption, design: .rounded).monospacedDigit().weight(.medium))
                    .foregroundStyle(GrymniaDesign.secondaryText)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct StatCard: View {
    let emoji: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(emoji)
                .font(.system(size: 30))
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(GrymniaDesign.secondaryText)
            Text(value)
                .font(.system(.title3, design: .rounded).monospacedDigit().weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tint.opacity(0.12))
        }
    }
}

struct EmptyState: View {
    let emoji: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 48))
            Text(title)
                .font(.system(.headline, design: .rounded))
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(GrymniaDesign.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
