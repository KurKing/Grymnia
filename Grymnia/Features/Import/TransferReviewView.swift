import GrymniaStatementParser
import SwiftUI

struct TransferReviewView: View {
    @EnvironmentObject private var store: GrymniaStore
    @State private var selected: Set<TransferMatch.ID> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💸 Transfers")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                    Text("Select matches that are money moving between your own accounts.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(GrymniaDesign.secondaryText)
                }
                .grymniaCard()

                VStack(spacing: 10) {
                    ForEach(store.ambiguousTransfers) { match in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if selected.contains(match.id) {
                                    selected.remove(match.id)
                                } else {
                                    selected.insert(match.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(selected.contains(match.id) ? "✅" : "💸")
                                    .font(.system(size: 28))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(match.amount.currencyText) \(match.currency)")
                                        .font(.system(.headline, design: .rounded).monospacedDigit())
                                    Text("Possible internal transfer")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(GrymniaDesign.secondaryText)
                                }

                                Spacer()
                            }
                            .padding(14)
                            .background {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(selected.contains(match.id) ? GrymniaDesign.primary.opacity(0.12) : Color.secondary.opacity(0.08))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .grymniaCard()
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(GrymniaDesign.background)
        .navigationTitle("Review")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("✅ Confirm") {
                    store.confirmAmbiguousTransfers(selected)
                }
                .disabled(selected.isEmpty)
            }
        }
    }
}
