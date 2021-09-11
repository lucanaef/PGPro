//
//  CryptographyService.swift
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

enum CryptographyError: Error {
    case emptyMessage
    case invalidMessage
    case requiresPassphrase
    case wrongPassphrase
    case frameworkError(_ error: Error)
    case failedEncryption
    case failedDecryption
}

enum ArmorParsingError: Error {
    case missingHeader
    case missingFooter
    case checksumMismatch
    case invalidMessageFormat
}

class CryptographyService {

    private init() {}

    /**
     Encrypts and signs a message.
     *Note*: If `contacts` contains a keys that includes a private keys,
     this method will also sign the message with that key.
     (That's how the framework call works)[https://github.com/krzyzanowskim/ObjectivePGP/issues/97].

     - Parameters:
        - message: A string to be encrypted and signed
        - contacts: The contacts (keys) for whom the message should be encrypted for.
        - signatures: The contacts (keys) that sign the message (optional).
        - passphrase: Handler for passphrase protected keys. Return passphrase for a key in question.

     - Throws:
        - `CryptographyError.emptyMessage` if the `message` contains an empty string.
        - `CryptographyError.invalidMessage` if the `message` can't be UTF8-encoded.
        - `CryptographyError.frameworkError` if ObjectivePGP throws an error during encryption.
        - `CryptographyError.failedEncryption` if the called wants to sign messages without providing a passphrase handler.

     - Returns: A new string containing the encrypted, (signed) and armored message.
     */
    static func encrypt(message: String, for contacts: [Contact], by signatures: [Contact]? = nil, passphraseForContact passphrase: ((Contact) -> String?)? = nil) throws -> String {
        guard message != "" else { throw CryptographyError.emptyMessage }
        guard let messageData = message.data(using: .utf8) else { throw CryptographyError.invalidMessage }

        // Get encryption keys
        var keys = contacts.map { $0.key }
        assert(keys.count > 0, "CryptographyService.encrypt(for: \(contacts)): Argument contains no contact with supported OpenPGP key.")

        // Get signing keys
        var signMessage = false
        if let signatures = signatures, !signatures.isEmpty {
            signMessage = true
            // Check that passphrase is not nil
            guard passphrase != nil else {
                throw CryptographyError.failedEncryption
            }
            let signingKeys = signatures.map { $0.key }
            keys.append(contentsOf: signingKeys)
        }

        // Encrypt (and sign) the message
        do {
            let encryptedBin = try ObjectivePGP.encrypt(messageData, addSignature: signMessage, using: keys, passphraseForKey: { key in
                let contact = ContactListService.get(forKey: key)
                return passphrase!(contact!) // hic sunt dracones 🐉
            })

            AppStoreReviewService.incrementReviewWorthyActionCount()
            return Armor.armored(encryptedBin, as: .message)
        } catch {
            throw CryptographyError.frameworkError(error)
        }
    }

    static func decrypt(message: String, by contact: Contact, withPassphrase passphrase: String?) throws -> String {
        let decryptionKey = contact.key
        let keyRequiresPassphrase = contact.keyRequiresPassphrase

        // Handle MESSAGE
        guard message != "" else { throw CryptographyError.emptyMessage }
        guard let range = message.range(of: #"-----BEGIN PGP MESSAGE-----(.|\n)*-----END PGP MESSAGE-----"#,
                                        options: .regularExpression) else {
            throw CryptographyError.invalidMessage
        }
        let message = String(message[range]) // trim message to armored part
        guard let messageData = message.data(using: .ascii) else { throw CryptographyError.invalidMessage }

        // Handle PASSPHRASE
        if (keyRequiresPassphrase) {
            guard passphrase != nil else {
                throw CryptographyError.requiresPassphrase
            }
            guard passphrase! != "" || passphraseIsCorrect("", for: decryptionKey) else {
                throw CryptographyError.requiresPassphrase
            }
            guard CryptographyService.passphraseIsCorrect(passphrase!, for: decryptionKey) else {
                throw CryptographyError.wrongPassphrase
            }
        }

        // Handle DECRYPTION
        do {
            let decryptedMessageData = try ObjectivePGP.decrypt(messageData,
                                                            andVerifySignature: false,
                                                            using: [decryptionKey],
                                                            passphraseForKey: {(_) -> (String?) in return passphrase})
            guard let decryptedMessage = String(data: decryptedMessageData, encoding: .utf8) else { throw CryptographyError.failedDecryption }
            AppStoreReviewService.incrementReviewWorthyActionCount()
            return decryptedMessage
        } catch {
            throw CryptographyError.frameworkError(error)
        }
    }

    static func passphraseIsCorrect(_ passphrase: String, for key: Key) -> Bool {
        do {
            _ = try key.decrypted(withPassphrase: passphrase)
        } catch {
            return false
        }
        return true
    }


    static func decryptionContacts(for message: String) -> [Contact] {

        let privateKeyContacts = ContactListService.get(ofType: .privateKey)
        var decryptionKeyIDs = [KeyID]()

        guard message != "" else {
            Log.d("empty message")
            return []
        }
        guard let range = message.range(of: #"-----BEGIN PGP MESSAGE-----(.|\n)*-----END PGP MESSAGE-----"#,
                                        options: .regularExpression) else {
            Log.d("invalid message")
            return []
        }
        guard let messageData = String(message[range]).data(using: .ascii) else {
            Log.d("string to data cast failed")
            return []
        }

        do {
            decryptionKeyIDs = try ObjectivePGP.recipientsKeyID(forMessage: messageData)
            Log.d("found key ids: \(decryptionKeyIDs)")
        } catch {
            Log.e(error)
            return []
        }

        for key in privateKeyContacts {
            Log.d("possible key ids: \(key.key.keyID)")
        }

        return privateKeyContacts.filter { decryptionKeyIDs.contains($0.key.keyID) }
    }

    /*
     Removes the OpenPGP ASCII armor (RFC 4880, section 6) of a message and returns the corresponding binary data.

     - Parameters:
        - message: ASCII armored message

     - Returns: Binary data corresponding to the ASCII armored message
     */
    static func dearmor(message: String) throws -> Data {
        // Get the base64-encoding substring

        let armoredBase64EncodedString = message.replacingOccurrences(of: "-----BEGIN PGP MESSAGE-----", with: "")
        guard armoredBase64EncodedString.count < message.count else {
            throw ArmorParsingError.missingHeader
        }

        var base64EncodedString = armoredBase64EncodedString.replacingOccurrences(of: "-----END PGP MESSAGE-----", with: "")
        guard base64EncodedString.count < armoredBase64EncodedString.count else {
            throw ArmorParsingError.missingFooter
        }

        base64EncodedString = base64EncodedString.filter {!$0.isWhitespace && !$0.isNewline}

        let base64EncodedStringComponents = base64EncodedString.components(separatedBy: "=")

        guard base64EncodedStringComponents.count == 3 else {
            throw ArmorParsingError.invalidMessageFormat
        }

        let base64MessageString = base64EncodedStringComponents[0] + "=" // re-add padding character
        // let base64ChecksumString = base64EncodedStringComponents[2] + "=" // re-add padding character

        // Validate checksum
        // TODO

        // Decode base64-endcoded string
        guard let messageData = Data(base64Encoded: base64MessageString, options: .ignoreUnknownCharacters) else {
            throw ArmorParsingError.invalidMessageFormat
        }

        Log.d("Hex. Message: \(messageData.hexEncodedString)")

        return messageData
    }



}
