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

    var readyForEncryption: Bool {
        !recipients.isEmpty && !message.isEmpty && message != placeholder
    }

    @Published var passphraseInputRequired: Bool = false

    var passphraseForKey: [Key: String] = [:]
    func passphrase(for key: Key) -> String? {
        return passphraseForKey[key]
    }
}
