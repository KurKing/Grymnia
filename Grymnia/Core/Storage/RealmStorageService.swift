import Foundation
import RealmSwift

@MainActor
final class RealmStorageService {
    private let keyProvider: RealmEncryptionKeyProvider

    init(keyProvider: RealmEncryptionKeyProvider) {
        self.keyProvider = keyProvider
    }

    func transactions() throws -> [NormalizedTransaction] {
        let realm = try realm()
        return realm.objects(TransactionObject.self)
            .sorted(byKeyPath: "operationDate", ascending: false)
            .map(\.snapshot)
    }

    func save(_ statementImport: StatementImport) throws -> StatementImport {
        let realm = try realm()
        var savedImport = statementImport

        try realm.write {
            if realm.object(ofType: AccountObject.self, forPrimaryKey: statementImport.accountID) == nil {
                realm.add(AccountObject(importSummary: statementImport), update: .modified)
            }

            var savedTransactions: [NormalizedTransaction] = []
            var duplicates = 0

            for transaction in statementImport.transactions {
                if realm.object(ofType: TransactionObject.self, forPrimaryKey: transaction.importFingerprint) != nil {
                    duplicates += 1
                    continue
                }
                realm.add(TransactionObject(transaction: transaction), update: .modified)
                savedTransactions.append(transaction)
            }

            savedImport.transactions = savedTransactions
            savedImport.duplicateCount = duplicates
        }

        return savedImport
    }

    func markInternalTransfers(_ matches: [TransferMatch]) throws {
        let realm = try realm()
        let ids = Set(matches.flatMap { [$0.outgoingID, $0.incomingID] })
        try realm.write {
            for id in ids {
                guard let object = realm.object(ofType: TransactionObject.self, forPrimaryKey: id) else {
                    continue
                }
                object.typeRaw = TransactionType.internalTransfer.rawValue
                object.categoryRaw = TransactionCategory.transfers.rawValue
            }
        }
    }

    func renameAccount(id: String, alias: String) throws {
        let realm = try realm()
        try realm.write {
            realm.object(ofType: AccountObject.self, forPrimaryKey: id)?.alias = alias
            let transactions = realm.objects(TransactionObject.self).where { $0.accountID == id }
            for transaction in transactions {
                transaction.accountAlias = alias
            }
        }
    }

    private func realm() throws -> Realm {
        var config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { _, _ in }
        )
        config.encryptionKey = try keyProvider.key()
        return try Realm(configuration: config)
    }
}
