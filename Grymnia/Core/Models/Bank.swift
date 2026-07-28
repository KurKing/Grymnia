import Foundation

enum Bank: String, CaseIterable, Identifiable, Codable {
    case monobank
    case creditAgricole

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monobank:
            "Monobank"
        case .creditAgricole:
            "Credit Agricole"
        }
    }
}
