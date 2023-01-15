//
//  EncryptionViewModel.swift
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

class EncryptionViewModel: ObservableObject {
    @Published var recipients: Set<Contact> = []
    @Published var signers: Set<Contact> = [] {
        didSet {
            passphraseInputRequired = signers.contains { $0.requiresPassphrase }
        }
    }

    let placeholder = "Type here to enter your message..."
    @Published var message: String = "Type here to enter your message..."

    var readyForEncryptionOrPassphrases: Bool {
        !recipients.isEmpty && !message.isEmpty && message != placeholder
    }

    @Published var passphraseInputRequired: Bool = false

    var somePassphrasesRequired: Bool {
        return !signers.filter({ $0.requiresPassphrase }).allSatisfy({ contact in
            if let key = contact.primaryKey, let passphrase = passphrase(for: key) {
                return OpenPGP.verifyPassphrase(passphrase, for: key)
            } else {
                Log.d("returning false...")
                return false
            }
        })
    }

    var passphraseForKey: [Key: String] = [:]
    func passphrase(for key: Key) -> String? {
        return passphraseForKey[key]
    }

    func encrypt() throws -> String {
        return try OpenPGP.encrypt(message: message, for: Array(recipients), signed: Array(signers), passphraseForKey: passphrase)
    }
}
