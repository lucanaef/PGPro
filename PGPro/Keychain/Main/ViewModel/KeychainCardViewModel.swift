//
//  KeychainCardViewModel.swift
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

class KeychainCardViewModel: ObservableObject {
    @Published var contact: Contact
    @Published var selected: Bool

    init(contact: Contact, selected: Bool) {
        self.contact = contact
        self.selected = selected
    }

    var name: String {
        contact.name
    }

    var email: String {
        contact.email
    }

    var keyID: String {
        contact.primaryKey?.keyID.shortIdentifier.insertSeparator(" ", atEvery: 4) ?? "-"
    }

    var fingerprint: String {
        contact.fingerprint?.insertSeparator(" ", atEvery: 4) ?? "-"
    }

    var expirationDate: String {
        contact.expirationDateString ?? "Never"
    }
}
