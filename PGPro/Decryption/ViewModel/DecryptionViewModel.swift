//
//  DecryptionViewModel.swift
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

class DecryptionViewModel: ObservableObject {
    @Published var ciphertext: String?

    @Published var decryptionKey: Set<Contact> = Set() {
        didSet {
            passphraseInputRequired = decryptionKey.contains { $0.requiresPassphrase }
        }
    }

    @Published var decryptionResult: OpenPGP.DecryptionResult?

    var readyForDecryptionOrPassphrases: Bool {
        !(ciphertext?.isEmpty ?? true) && (ciphertext?.isOpenPGPCiphertext ?? false) && !decryptionKey.isEmpty
    }

    // MARK: - Passphrase Handling

    @Published var passphraseInputRequired: Bool = false

    var somePassphrasesRequired: Bool {
        return !decryptionKey.filter({ $0.requiresPassphrase }).allSatisfy({ contact in
            if let key = contact.primaryKey, let passphrase = passphrase(for: key) {
                return OpenPGP.verifyPassphrase(passphrase, for: key)
            } else {
                return false
            }
        })
    }

    var passphraseForKey: [Key: String] = [:]
    func passphrase(for key: Key) -> String? {
        return passphraseForKey[key]
    }

    // MARK: - Decryption

    func decrypt() {
        guard let ciphertext else {
            Log.e("Ciphertext cannot be empty!")
            return
        }

        if let contact = decryptionKey.first, let key = contact.primaryKey {
            do {
                self.decryptionResult = try OpenPGP.decrypt(message: ciphertext, for: contact, withPassphrase: passphrase(for: key))
            } catch {
                Log.e(error)
                return
            }
        } else {
            Log.e("Failed to unwrap first (and only) decryption key.")
        }
    }

    // MARK: - Clearing

    func clear() {
        self.ciphertext = nil
        self.decryptionKey.removeAll()
    }

    var isClear: Bool {
        self.ciphertext == nil && self.decryptionKey.isEmpty
    }
}
