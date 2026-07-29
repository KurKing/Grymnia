import Combine
import Foundation
import GrymniaStatementParser
import PDFKit

@MainActor
final class GrymniaStore: ObservableObject {
    @Published private(set) var transactions: [NormalizedTransaction] = []
    @Published var pendingImport: StatementImport?
    @Published var ambiguousTransfers: [TransferMatch] = []
    @Published var alertMessage: String?
    @Published var isImporting = false

    private let storage: RealmStorageService
    private let parserRegistry: ParserRegistry

    init() {
        self.storage = RealmStorageService(keyProvider: RealmEncryptionKeyProvider())
        self.parserRegistry = ParserRegistry()
    }

    init(storage: RealmStorageService, parserRegistry: ParserRegistry) {
        self.storage = storage
        self.parserRegistry = parserRegistry
    }

    func load() {
        do {
            transactions = try storage.transactions()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func importPDF(from url: URL) {
        isImporting = true
        defer { isImporting = false }

        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard let document = PDFDocument(url: url) else {
            alertMessage = "Could not open selected PDF."
            return
        }

        do {
            pendingImport = try parserRegistry.parse(document)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func savePendingImport() {
        guard let pendingImport else { return }

        do {
            let saved = try storage.save(pendingImport)
            self.pendingImport = nil
            transactions = try storage.transactions()

            let matches = InternalTransferMatcher.matches(in: transactions)
            let highConfidence = matches.filter { $0.confidence == .high }
            ambiguousTransfers = matches.filter { $0.confidence == .ambiguous }
            try storage.markInternalTransfers(highConfidence)
            transactions = try storage.transactions()

            var parts = ["Saved \(saved.transactions.count) transactions."]
            if saved.duplicateCount > 0 {
                parts.append("Skipped \(saved.duplicateCount) duplicates.")
            }
            if !highConfidence.isEmpty {
                parts.append("Marked \(highConfidence.count) internal transfers.")
            }
            alertMessage = parts.joined(separator: " ")
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func confirmAmbiguousTransfers(_ selected: Set<TransferMatch.ID>) {
        let matches = ambiguousTransfers.filter { selected.contains($0.id) }
        do {
            try storage.markInternalTransfers(matches)
            ambiguousTransfers.removeAll { selected.contains($0.id) }
            transactions = try storage.transactions()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func cancelPendingImport() {
        pendingImport = nil
    }
}
