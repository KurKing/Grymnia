import SwiftUI
import UniformTypeIdentifiers

struct ImportButton: View {
    @EnvironmentObject private var store: GrymniaStore
    @State private var isImporterPresented = false

    var body: some View {
        Button {
            isImporterPresented = true
        } label: {
            HStack(spacing: 8) {
                Text(store.isImporting ? "🔍" : "📥")
                Text(store.isImporting ? "Parsing..." : "Import")
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(GrymniaDesign.primary)
        .disabled(store.isImporting)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                store.importPDF(from: url)
            case .failure(let error):
                store.alertMessage = error.localizedDescription
            }
        }
    }
}
