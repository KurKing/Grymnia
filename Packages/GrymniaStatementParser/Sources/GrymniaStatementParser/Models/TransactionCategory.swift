import Foundation

public enum TransactionCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case groceries
    case restaurants
    case fastFood
    case fuel
    case pharmacy
    case home
    case clothes
    case pets
    case transport
    case utilities
    case mobile
    case subscriptions
    case transfers
    case fees
    case income
    case other

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .groceries: "Groceries"
        case .restaurants: "Restaurants"
        case .fastFood: "Fast Food"
        case .fuel: "Fuel"
        case .pharmacy: "Pharmacy"
        case .home: "Home"
        case .clothes: "Clothes"
        case .pets: "Pets"
        case .transport: "Transport"
        case .utilities: "Utilities"
        case .mobile: "Mobile"
        case .subscriptions: "Subscriptions"
        case .transfers: "Transfers"
        case .fees: "Fees"
        case .income: "Income"
        case .other: "Other"
        }
    }
}
