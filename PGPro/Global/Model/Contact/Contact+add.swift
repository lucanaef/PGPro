//
//  Contact+add.swift
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

import CoreData
import ObjectivePGP

extension Contact {
    private static let moc = DataController.shared.container.viewContext

    struct ContactAddResult: CustomStringConvertible {
        var successful: Int
        var failed: Int

        init() {
            successful = 0
            failed = 0
        }

        var description: String {
            if successful == 1 {
                if failed == 1 {
                    return "\(successful) key successfully added. \(failed) key failed to add."
                } else {
                    return "\(successful) key successfully added. \(failed) keys failed to add."
                }
            } else {
                if failed == 1 {
                    return "\(successful) keys successfully added. \(failed) key failed to add."
                } else {
                    return "\(successful) keys successfully added. \(failed) keys failed to add."
                }
            }
        }
    }

    static func add(from string: String) -> ContactAddResult {
        var result = ContactAddResult()

        guard let keyData = string.data(using: .ascii) else {
            Log.e("Failed to get data from string.")
            return result
        }

        do {
            let keys = try OpenPGP.keys(from: keyData)
            for key in keys {
                let success = Contact.add(from: key)

                if success {
                    result.successful += 1
                } else {
                    result.failed += 1
                }
            }
        } catch {
            Log.e(error)
            return result
        }

        return result
    }

    static func add(name: String, email: String, key: Key) -> Bool {
        // Check whether contact with this key (i.e. fingerprint and type) already exists.
        guard !exisits(with: key) else { return false }

        let contact = Contact(context: moc)
        contact.name = name
        contact.email = email

        do {
            contact.keyData = try key.export() as NSData
            try moc.save()
        } catch {
            Log.e(error)
            return false
        }

        return true
    }

    static func add(from key: Key) -> Bool {
        let userID: String = key.publicKey?.primaryUser?.userID ?? key.secretKey?.primaryUser?.userID ?? ""

        var name = userID
            .replacingOccurrences(of: "\\s?\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s?\\<[^>]*\\>", with: "", options: .regularExpression)

        guard let email = userID.slice(from: "<", to: ">") else { return false }
        guard email.isValidEmail else { return false }

        // Use email as name as a fallback
        if name.isEmpty { name = email }

        let success = Contact.add(name: name, email: email, key: key)

        return success
    }

    static func add(from keys: [Key]) -> ContactAddResult {
        var result = ContactAddResult()
        for key in keys {
            let success = Contact.add(from: key)
            if success {
                result.successful += 1
            } else {
                result.failed += 1
            }
        }
        return result
    }

    static func exisits(with key: Key) -> Bool {
        if let fetchRequest = Contact.fetchRequest() as? NSFetchRequest<Contact> {
            do {
                let contacts = try moc.fetch(fetchRequest)
                return contacts.contains { contact in
                    if let primaryKey = contact.primaryKey {
                        return primaryKey.keyID == key.keyID && primaryKey.isSecret == key.isSecret
                    } else {
                        return false
                    }
                }
            } catch {
                Log.e(error)
                return false
            }
        } else {
            Log.e("Failed to build fetchRequest.")
            return false
        }
    }
}
