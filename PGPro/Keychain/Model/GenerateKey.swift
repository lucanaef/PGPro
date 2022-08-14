//
//  GenerateKey.swift
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

enum GenerateKeyError: Error {
    case nameNil
    case nameEmpty
    case emailAddressNil
    case emailAddressEmpty
    case emailAddressInvalid
    case passphraseMismatch
    case nonUnique
}

class GenerateKey {

    var name: String?
    var email: String?
    var passphrase: String?
    var confirmedPassphrase: String?

    func generate() throws {
        // Sanitize Inputs
        if passphrase == "" {
            passphrase = nil
        }
        if confirmedPassphrase == "" {
            confirmedPassphrase = nil
        }

        // Validate Inputs
        guard let name = name else { throw GenerateKeyError.nameNil }
        guard let email = email else { throw GenerateKeyError.emailAddressNil }
        guard name != "" else { throw GenerateKeyError.nameEmpty }
        guard email != "" else { throw GenerateKeyError.emailAddressEmpty }
        guard email.isValidEmail() else { throw GenerateKeyError.emailAddressInvalid }
        guard passphrase == confirmedPassphrase else { throw GenerateKeyError.passphraseMismatch }

        // Generate Key
        let key = KeyGenerator().generate(for: "\(name) <\(email)>", passphrase: passphrase)

        // Create Contact
        let result = ContactListService.add(name: name, email: email, key: key)
        if result.duplicates == 1 {
            throw GenerateKeyError.nonUnique
        } else {
            AppStoreReviewService.incrementReviewWorthyActionCount()
        }

    }

    enum Sections: Int, CaseIterable {
        case contact = 0
        case security = 1

        var rows: Int {
            switch self {
            case .contact:
                return ContactSection.allCases.count
            case .security:
                return SecuritySection.allCases.count
            }
        }

        var header: String? {
            switch self {
            case .contact:
                return ContactSection.header
            case .security:
                return SecuritySection.header
            }
        }

        var footer: String? {
            switch self {
            case .contact:
                return ContactSection.footer
            case .security:
                return SecuritySection.footer
            }
        }

    }

    enum ContactSection: Int, CaseIterable {
        case name = 0
        case email = 1

        static var header: String? {
            "Contact Info"
        }

        static var footer: String? {
            nil
        }

        var placeholder: String? {
            switch self {
            case .name:
                return "Name"
            case .email:
                return "Email Address"
            }
        }
    }

    enum SecuritySection: Int, CaseIterable {
        case passphrase = 0
        case confirmPassphrase = 1
        case passwordStength = 2

        static var header: String? {
            "Security"
        }

        static var footer: String? {
            "Note: If you forget your passphrase, there is no way to recover it."
        }

        var placeholder: String? {
            switch self {
            case .passphrase:
                return "Passphrase"
            case .confirmPassphrase:
                return "Confirm Passphrase"
            case .passwordStength:
                return nil
            }
        }
    }

}
