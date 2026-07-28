import Foundation
import KeychainAccess
import Security

struct RealmEncryptionKeyProvider {
    private let keychain = Keychain(service: "com.kurking.Grymnia.realm")
        .accessibility(.afterFirstUnlockThisDeviceOnly)
    private let keyName = "realm-encryption-key"

    func key() throws -> Data {
        if let existing = try keychain.getData(keyName), existing.count == 64 {
            return existing
        }

        var bytes = [UInt8](repeating: 0, count: 64)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw SecurityError.keyGenerationFailed(status)
        }

        let data = Data(bytes)
        try keychain.set(data, key: keyName)
        return data
    }
}

enum SecurityError: LocalizedError {
    case keyGenerationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed(let status):
            "Could not generate Realm encryption key. Security status: \(status)."
        }
    }
}
