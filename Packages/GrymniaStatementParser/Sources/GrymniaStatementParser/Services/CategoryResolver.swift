import Foundation

enum CategoryResolver {
    static func category(for transaction: ParsedTransactionDraft) -> TransactionCategory {
        if transaction.type == .fee {
            return .fees
        }
        if transaction.type == .income {
            return .income
        }
        if transaction.type == .internalTransfer {
            return .transfers
        }
        if let mcc = transaction.mcc, let category = category(forMCC: mcc) {
            return category
        }

        let key = MerchantNormalizer.key(transaction.merchant + " " + transaction.rawDescription)
        if key.contains("SILPO") || key.contains("THRASH") {
            return .groceries
        }
        if key.contains("EPIT") {
            return .home
        }
        if key.contains("MCDONALD") || key.contains("MAKDONALD") {
            return .fastFood
        }
        if key.contains("AZK") || key.contains("OKKO") || key.contains("WOG") {
            return .fuel
        }
        return .other
    }

    static func category(forMCC mcc: Int) -> TransactionCategory? {
        switch mcc {
        case 5411, 5499:
            .groceries
        case 5812:
            .restaurants
        case 5814:
            .fastFood
        case 5541, 5542:
            .fuel
        case 5912:
            .pharmacy
        case 5211, 5200, 5712:
            .home
        case 5651, 5691:
            .clothes
        case 742:
            .pets
        case 4111, 4121, 4131, 4789:
            .transport
        case 4900:
            .utilities
        case 4814:
            .mobile
        case 5818, 4899:
            .subscriptions
        default:
            nil
        }
    }
}
