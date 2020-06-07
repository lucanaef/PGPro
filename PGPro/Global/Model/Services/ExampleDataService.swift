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
    
    private init() {}
    
    static func createExampleDataset() {
        let keyGen = KeyGenerator()
        let exampleContacts: [(String, String, String?, Bool, Bool)] = [
        //   NAME                   EMAIL ADDRESS                 PASSPHRASE    HAS PUBLIC KEY      HAS PRIVATE KEY
            ("Winston Smith",       "winston.smith@pgpro.app",    nil,          true,               true),
            ("O'Brien",             "obrien@pgpro.app",           nil,          true,               false),
            ("Julia",               "julia@pgpro.app",            "jules",      true,               true),
            ("Mr. Charrington",     "mr.charrington@pgpro.app",   nil,          false,              true),
            ("Syme",                "syme@pgpro.app",             nil,          false,              true),
            ("Parsons",             "parsons@pgpro.app",          nil,          false,              true),
            ("Emmanuel Goldstein",  "e.goldstein@pgpro.app",      nil,          false,              true),
            ("Tillotson",           "tillotson@pgpro.app",        "",           true,               true)
        ]

        for index in exampleContacts.indices {
            let (name, email, passphrase, hasPublicKey, hasPrivateKey) = exampleContacts[index]
            let genKey = keyGen.generate(for: email, passphrase: passphrase)
            let publicKey = hasPublicKey ? genKey.publicKey : nil
            let privateKey = hasPrivateKey ? genKey.secretKey : nil
            let key = Key(secretKey: privateKey, publicKey: publicKey)
            _ = ContactListService.add(name: name, email: email, key: key)
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
