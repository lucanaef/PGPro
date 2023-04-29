//
//  MockData.swift
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

class MockData {
    private init() {}

    // swiftlint:disable large_tuple
    private static let users: [(String, String, String)] = [
        ("Winston Smith", "winston.smith@pgpro.app", "winston"),
        ("O'Brien", "obrien@pgpro.app", "obrien"),
        ("Julia", "julia@pgpro.app", "julia"),
        ("Mr. Charrington", "mr.charrington@pgpro.app", "charrington"),
        ("Syme", "syme@pgpro.app", "syme"),
        ("Parsons", "parsons@pgpro.app", "parsons"),
        ("Emmanuel Goldstein", "e.goldstein@pgpro.app", "emmanuel"),
        ("Tillotson", "tillotson@pgpro.app", "tillotson")
    ]
    // swiftlint:enable large_tuple

    static var contacts: [Contact] {
        var data: [Contact] = []
        for user in users {
            let keyGenerationResult = OpenPGP.generateKey(for: user.0, email: user.1, passphrase: user.2)
            switch keyGenerationResult {
                case .failure:
                    continue

                case .success(let key):
                    let moc = DataController.shared.container.viewContext
                    let contact = Contact(context: moc)
                    contact.name = user.0
                    contact.email = user.1
                    do {
                        contact.keyData = try key.export() as NSData
                        data.append(contact)
                    } catch {
                        Log.e(error)
                        continue
                    }
            }
        }

        return data
    }
}
