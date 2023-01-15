//
//  OpenPGP.swift
//  PGPro
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ObjectivePGP

class OpenPGP {
    private init() {}

    static func keys(from data: Data) throws -> [Key] {
        let keys = try ObjectivePGP.readKeys(from: data)
        return keys
    }

    static func key(from data: Data) throws -> Key {
        let keys = try self.keys(from: data)
        return keys.first!
    }

    // MARK: - Key Generation

    enum KeyGenerationError: Error, CustomStringConvertible {
        case invalidInputName
        case invalidInputEmail
        case invalidInputPassphrase

        var description: String {
            switch self {
            case .invalidInputName: return "Invalid Input: Name"
            case .invalidInputEmail: return "Invalid Input: Email"
            case .invalidInputPassphrase: return "Invalid Input: Passphrase"
            }
        }
    }

    static func generateKey(for name: String, email: String, passphrase: String) -> Result<Key, KeyGenerationError> {
        guard !name.isEmpty else { return .failure(.invalidInputName) }
        guard email.isValidEmail else { return .failure(.invalidInputEmail) }
        guard !passphrase.isEmpty else { return .failure(.invalidInputPassphrase) }

        let userID = name + "<" + email + ">"
        let key = KeyGenerator().generate(for: userID, passphrase: passphrase)

        return .success(key)
    }

    // MARK: Encryption

    static func encrypt(message: String, for recipients: [Contact], signed: [Contact] = [], passphraseForKey passphrase: ((Key) -> String?)? = nil) throws -> String {
        guard !recipients.isEmpty else { throw OpenPGPError.failedEncryption(description: "There must be at least one recipient.") }
        guard !message.isEmpty else { throw OpenPGPError.emptyMessage }
        guard let messageData = message.data(using: .utf8) else { throw OpenPGPError.invalidMessage }

        // Collect encryption keys of recipients
        var encryptionKeys = recipients.map { $0.primaryKey }

        // Remove private key parts of encryption keys, because otherwise they would be used as signing keys
        encryptionKeys = encryptionKeys.map { Key(secretKey: nil, publicKey: $0?.publicKey) }

        // Collect signing keys
        let signingKeys = signed.map { $0.primaryKey }
        let addSignature = !signingKeys.isEmpty

        // Combine key sets and throw error if any key is nil
        let keys = try (encryptionKeys + signingKeys).filter { key in
            if key != nil {
                return true
            } else {
                throw OpenPGPError.failedEncryption(description: "Failed to unwrap key.")
            }
        }.compactMap { $0 }

        // Encrypt and sign the message
        do {
            let encryptedMessageData = try ObjectivePGP.encrypt(messageData, addSignature: addSignature, using: keys, passphraseForKey: passphrase)
            let armoredEncryptedMessageData = Armor.armored(encryptedMessageData, as: .message)
            return armoredEncryptedMessageData
        } catch {
            throw OpenPGPError.frameworkError(error)
        }
    }

    // MARK: Decryption

    static func decrypt(message: String, for contact: Contact, withPassphrase passphrase: String? = nil) throws -> String {
        // TODO: Implement
        return ""
    }

    // MARK: Public Helper Functions

    static func verifyPassphrase(_ passphrase: String, for key: Key) -> Bool {
        do {
            _ = try key.decrypted(withPassphrase: passphrase)
        } catch {
            return false
        }
        return true
    }

    // MARK: Private Helper Functions

}
