import Foundation

public enum Bank: String, CaseIterable, Identifiable, Codable, Sendable {
    case monobank
    case creditAgricole

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .monobank:
            "Monobank"
        case .creditAgricole:
            "Credit Agricole"
        }
    }
}
