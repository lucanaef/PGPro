//
//  GenerateKeyPairViewModel.swift
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
import SwiftUI

class GenerateKeyPairViewModel: ObservableObject {
    enum Field: Hashable {
        case name
        case email
        case passphrase
        case passphraseConfirm
    }

    @Published var name: String = ""
    @Published var email: String = ""

    @Published var passphrase: String = ""
    @Published var passphraseConfirm: String = ""

    // Normalized estimated passphrase strength value
    var passphraseEntropy: Float {
        return Navajo.entropy(of: passphrase)
    }

    var passphraseStrength: CGFloat {
        let strengthVal = min(128.0, passphraseEntropy) / 128.0
        print(strengthVal)
        return CGFloat(strengthVal)
    }

    var passphraseStrengthColor: Color {
        let strength = Navajo.passwordStrength(forEntropy: passphraseEntropy)

        switch strength {
        case .veryWeak:
            return Color(UIColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0))

        case .weak:
            return Color(UIColor(red: 0.90, green: 0.49, blue: 0.13, alpha: 1.0))

        case .reasonable:
            return Color(UIColor(red: 1.00, green: 0.75, blue: 0.28, alpha: 1.0))

        case .strong:
            return Color(UIColor(red: 0.13, green: 0.81, blue: 0.44, alpha: 1.0))

        case .veryStrong:
            return Color(UIColor(red: 0.03, green: 0.68, blue: 0.38, alpha: 1.0))
        }
    }

    var generateButtonEnabled: Bool {
        switch validateInput() {
        case .failure:
            return false

        case .success:
            return true
        }
    }

    var allFieldsEmpty: Bool {
        return name.isEmpty
            && email.isEmpty
            && passphrase.isEmpty
            && passphraseConfirm.isEmpty
    }

    func validateInput() -> Result<Void, GenerateKeyPairError> {
        if name.isEmpty {
            return .failure(.nameEmpty)
        } else if email.isEmpty {
            return .failure(.emailAddressEmpty)
        } else if !email.isValidEmail {
            return .failure(.emailAddressInvalid)
        } else if passphrase.isEmpty {
            return .failure(.passphraseEmpty)
        } else if passphraseConfirm.isEmpty {
            return .failure(.passphraseConfirmEmpty)
        } else if passphrase != passphraseConfirm {
            return .failure(.passphraseMismatch)
        } else {
            return .success(())
        }
    }

    func generateKey() -> Result<Void, Error> {
        // Validate input
        let validationResult = validateInput()
        if case .failure(let error) = validationResult {
            return .failure(error)
        }

        // Generate key
        let keyGenerationResult = OpenPGP.generateKey(for: name, email: email, passphrase: passphrase)
        switch keyGenerationResult {
        case .failure(let error):
            return .failure(error)

        case .success(let key):
            // Add key to keychain
            let success = Contact.add(name: name, email: email, key: key)
            if success {
                return .success(())
            } else {
                return .failure(GenerateKeyPairError.importFailed)
            }
        }
    }
}
