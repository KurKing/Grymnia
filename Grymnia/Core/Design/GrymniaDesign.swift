import SwiftUI
import GrymniaStatementParser
import UIKit

enum GrymniaDesign {
    static let primary = Color(hex: 0x5B5CEB)
    static let accent = Color(hex: 0x7C6CFF)
    static let success = Color(hex: 0x2ECC71)
    static let expense = Color(hex: 0xFF5A5F)
    static let warning = Color(hex: 0xFFB020)
    static let lightBackground = Color(hex: 0xF7F7F5)
    static let darkBackground = Color(hex: 0x111111)
    static let secondaryText = Color(hex: 0x8E8E93)
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 17 / 255, green: 17 / 255, blue: 17 / 255, alpha: 1)
            : UIColor(red: 247 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1)
    })

    static let categoryPastels: [Color] = [
        Color(hex: 0x9FB7FF),
        Color(hex: 0xF9A8B8),
        Color(hex: 0xA8E6CF),
        Color(hex: 0xFFD3A5),
        Color(hex: 0xC7B9FF),
        Color(hex: 0xBDE0FE),
        Color(hex: 0xFFF1A8),
        Color(hex: 0xD7C0AE)
    ]
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension View {
    func grymniaCard() -> some View {
        padding(18)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
            }
    }
}

extension TransactionCategory {
    var emoji: String {
        switch self {
        case .groceries: "🛒"
        case .restaurants: "🍕"
        case .fastFood: "🍔"
        case .fuel: "⛽️"
        case .pharmacy: "🏥"
        case .home: "🏡"
        case .clothes: "🛍"
        case .pets: "🐶"
        case .transport: "🚌"
        case .utilities: "💡"
        case .mobile: "📱"
        case .subscriptions: "🎬"
        case .transfers: "💸"
        case .fees: "🧾"
        case .income: "💼"
        case .other: "◻️"
        }
    }

    var displayTitle: String {
        "\(emoji) \(title)"
    }
}
