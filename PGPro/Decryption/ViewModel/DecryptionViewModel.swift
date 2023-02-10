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

class DecryptionViewModel: ObservableObject {
    @Published var ciphertext: String?
    @Published var decryptionKey: Set<Contact> = Set()
    @Published var decryptionResult: OpenPGP.DecryptionResult?

    var readyForDecryptionOrPassphrases: Bool {
        !(ciphertext?.isEmpty ?? true) && (ciphertext?.isOpenPGPCiphertext ?? false) && !decryptionKey.isEmpty
    }

    func decrypt() {
        #warning("Decryption with passphrase not implemented!")
        guard let ciphertext else {
            Log.e("Ciphertext cannot be empty!")
            return
        }

        if let contact = decryptionKey.first {
            do {
                self.decryptionResult = try OpenPGP.decrypt(message: ciphertext, for: contact)
            } catch {
                Log.e(error)
                return
            }
        } else {
            Log.e("Failed to unwrap first (and only) decryption key.")
        }
    }
}
