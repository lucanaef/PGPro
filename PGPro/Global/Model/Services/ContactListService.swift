//
//  ContactListService.swift
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
import CoreData
import ObjectivePGP


class ContactListService {

    private init() {}
    private static var contactList: [Contact] = [] {
        didSet {
            NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange, object: nil)
        }
    }

    /// Returns the number of contacts in the list
    class var count: Int { contactList.count }

    class func loadPersistentData() {
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        do {
            contactList = try PersistenceService.context.fetch(fetchRequest)
            let removedContacts = cleanUp()
            Log.i("Removed \(removedContacts) contacts after loading persistent data")
            contactList.sort()
        } catch {
            Log.s("Failed to Load Persistent Data!")
        }
    }

    class func get(ofType type: Constants.KeyType) -> [Contact] {
        switch type {
        case .publicKey:
            return contactList.filter { $0.key.isPublic }
        case .privateKey:
            return contactList.filter { $0.key.isSecret }
        case .both:
            return contactList
        case .none:
            return [Contact]()
        }
    }

    // MARK - Mutate List
    class func add(name: String, email: String, key: Key) -> ContactListResult {
        // Check that no contact with this email address already exists
        guard !contactList.contains( where: {
            (contact) -> Bool in contact.email == email
        }) else {
            return ContactListResult(successful: 0, unsupported: 0, duplicates: 1)
        }
        
        // Create new contact
        let contact = Contact(context: PersistenceService.context)
        contact.name = name
        contact.email = email
        do {
            let keyData = try key.export() as NSData
            guard (keyData.length > 0) else {
                return ContactListResult(successful: 0, unsupported: 1, duplicates: 0)
            }
            contact.keyData = keyData
        } catch {
            return ContactListResult(successful: 0, unsupported: 1, duplicates: 0)
        }
            
        // Add contact to in-memory and persistent data storage
        contactList.append(contact)
        contactList.sort()
        PersistenceService.save()
        
        return ContactListResult(successful: 1, unsupported: 0, duplicates: 0)
    }

    class func importFrom(_ keys: [Key]) -> ContactListResult {
        var importResult = ContactListResult(successful: 0, unsupported: 0, duplicates: 0)

        for key in keys {
            var primaryUser: User?
            if (key.isSecret) {
                guard let privateKey = key.secretKey else { continue }
                primaryUser = privateKey.primaryUser
            } else {
                guard let publicKey = key.publicKey else { continue }
                primaryUser = publicKey.primaryUser
            }

            if let primaryUser = primaryUser {
                let components = primaryUser.userID.components(separatedBy: "<")

                var name: String
                var email: String

                if (components.count == 2) {
                    name = String(components[0].dropLast())
                    email = String(components[1].dropLast())
                } else if (components.count == 1 && components[0].isValidEmail()) {
                    name = components[0]
                    email = components[0]
                } else {
                    break // skip if no name/email address can be inferred from data
                }

                let addResult = add(name: name, email: email, key: key)
                importResult.successful += addResult.successful
                importResult.duplicates += addResult.duplicates

            } else { continue }
        }

        importResult.unsupported = cleanUp()
        importResult.successful -= importResult.unsupported

        return importResult
    }

    class func rename(_ contact: Contact, to newName: String, withEmail newEmail: String) -> Bool {
        // Check if contact with this email address already exists
        for cntct in ContactListService.contactList where (cntct.email == newEmail && contact.email != newEmail) {
            return false
        }

        contact.name = newName
        contact.email = newEmail

        contactList.sort()

        NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange, object: nil)
        
        return true
    }

    class func remove(_ contact: Contact) {
        // Delete contact from persistent data
        PersistenceService.context.delete(contact)
        PersistenceService.save()

        // Delete contact from in-memory data
        contactList = contactList.filter { $0 != contact}

        // Notify observers about change
        NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange, object: nil)
    }

    class func deleteAllData() {
        // Delete in-memory and persistent data
        PersistenceService.context.reset()
        contactList = []
        NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange, object: nil)
    }

    // MARK - Private Helper Functions
    private class func cleanUp() -> Int {
        var count = 0
        for contact in contactList where (!contact.key.isPublic && !contact.key.isSecret) {
            remove(contact)
            count += 1
        }
        return count
    }
}

/// Return type when adding keys to the contact list
struct ContactListResult {
    /// Number of successfuly added contacts
    var successful: Int
    /// Number omitted contacts due to unsupported keys
    var unsupported: Int
    /// Number omitted contacts due to duplicate email addresses
    var duplicates: Int
}
