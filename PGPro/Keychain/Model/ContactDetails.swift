//
//  ContactDetails.swift
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

class ContactDetails {

    private var contact: Contact
    private var key: Key {
        contact.key
    }

    init(for contact: Contact) {
        self.contact = contact
    }

    // MARK: - Properties

    var name: String {
        contact.name
    }
    var email: String {
        contact.email
    }
    var userID: String {
        contact.userID
    }

    var armoredPublicKey: String {
        contact.getArmoredKey(as: .public) ?? ""
    }
    var armoredPrivateKey: String {
        contact.getArmoredKey(as: .secret) ?? ""
    }

    var keyIsValid: Bool {
        key.isPublic || key.isSecret
    }

    var keyID: String? {
        key.keyID.shortIdentifier.insertSeparator(" ", atEvery: 4)
    }

    var keyType: String? {
        var type = "None"
        if key.isPublic && key.isSecret {
            type = "Public & Private"
        } else if key.isPublic {
            type = "Public"
        } else if key.isSecret {
            type = "Private"
        }
        return type
    }

    var keyExpirationDate: Date? {
        key.expirationDate
    }

    var keyFingerprint: String? {
        return contact.keyFingerprint
    }

    // MARK: - Intents

    enum RenameError: Error {
        case cantBeNil
        case cantBeEmpty
        case alreadyExists
    }

    func rename(to name: String?) throws {

        guard let newName = name else { throw RenameError.cantBeNil }
        guard newName != "" else { throw RenameError.cantBeEmpty }

        let success = ContactListService.rename(contact, to: newName, withEmail: email)

        if !success { throw RenameError.alreadyExists }

    }
}
