//
//  ExampleDataService.swift
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

/**
     Generate example entries for screenshots and debugging
*/
class ExampleDataService {

    private struct ExampleContact {
        let name: String
        let emailAddress: String
        let passphrase: String?
        let hasPublicKey: Bool
        let hasPrivateKey: Bool
    }

    private init() {}

    static func createExampleDataset() {
        let keyGen = KeyGenerator()
        let exampleContacts: [ExampleContact] = [
        //   NAME                   EMAIL ADDRESS                 PASSPHRASE    HAS PUBLIC KEY      HAS PRIVATE KEY
            ExampleContact(name: "Winston Smith", emailAddress: "winston.smith@pgpro.app", passphrase: nil, hasPublicKey: true, hasPrivateKey: true),
            ExampleContact(name: "O'Brien", emailAddress: "obrien@pgpro.app", passphrase: nil, hasPublicKey: true, hasPrivateKey: false),
            ExampleContact(name: "Julia", emailAddress: "julia@pgpro.app", passphrase: "jules", hasPublicKey: true, hasPrivateKey: true),
            ExampleContact(name: "Mr. Charrington", emailAddress: "mr.charrington@pgpro.app", passphrase: nil, hasPublicKey: false, hasPrivateKey: true),
            ExampleContact(name: "Syme", emailAddress: "syme@pgpro.app", passphrase: nil, hasPublicKey: false, hasPrivateKey: true),
            ExampleContact(name: "Parsons", emailAddress: "parsons@pgpro.app", passphrase: nil, hasPublicKey: false, hasPrivateKey: true),
            ExampleContact(name: "Emmanuel Goldstein", emailAddress: "e.goldstein@pgpro.app", passphrase: nil, hasPublicKey: false, hasPrivateKey: true),
            ExampleContact(name: "Tillotson", emailAddress: "tillotson@pgpro.app", passphrase: "", hasPublicKey: true, hasPrivateKey: true)
        ]

        for index in exampleContacts.indices {
            let contact = exampleContacts[index]
            let genKey = keyGen.generate(for: contact.emailAddress, passphrase: contact.passphrase)
            let publicKey = contact.hasPublicKey ? genKey.publicKey : nil
            let privateKey = contact.hasPrivateKey ? genKey.secretKey : nil
            let key = Key(secretKey: privateKey, publicKey: publicKey)
            _ = ContactListService.add(name: contact.name, email: contact.emailAddress, key: key)
        }
    }

    static func createLargeDataset(numberOfContacts: Int) {
        for iteration in 0..<numberOfContacts {
            let name = "PGPro User \(iteration)"
            let email = "user\(iteration)@pgpro.app"
            let key = KeyGenerator().generate(for: email, passphrase: nil)
            _ = ContactListService.add(name: name, email: email, key: key)
        }
    }

}
