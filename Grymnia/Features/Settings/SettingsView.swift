import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("⚙️ Settings")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                    Text("Private expense tracking. No bank login required.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(GrymniaDesign.secondaryText)

                    ImportButton()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .grymniaCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("🔒 Privacy")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                    SettingsRow(emoji: "📄", text: "PDFs are parsed locally and not stored.")
                    SettingsRow(emoji: "🔑", text: "Realm data is encrypted with a Keychain key.")
                    SettingsRow(emoji: "📵", text: "No bank login, cloud sync, or backend.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .grymniaCard()

                VStack(alignment: .leading, spacing: 14) {
                    Text("🏦 Supported banks")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                    SettingsRow(emoji: "🐱", text: "Monobank")
                    SettingsRow(emoji: "🌾", text: "Credit Agricole")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .grymniaCard()
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(GrymniaDesign.background)
        .navigationTitle("Settings")
    }
}

private struct SettingsRow: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 36)
            Text(text)
                .font(.system(.body, design: .rounded))
            Spacer(minLength: 0)
        }
    }
}
