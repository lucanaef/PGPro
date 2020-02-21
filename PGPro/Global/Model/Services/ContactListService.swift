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
    
    private init () {}
    
    private static var contactList: [Contact] = []
    
    /**
         Loads the persistent data into in-memory datastructure
    */
    static func loadPersistentData() {
        let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        do {
            self.contactList = try PersistenceService.context.fetch(fetchRequest)
            ContactListService.sort()
            NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange,
                                            object: nil
            )
        } catch {
            print("Failed to Load Saved Data!")
        }
    }
    
    /**
         Sorts the in-memory contact list alphabetically by name
    */
    static func sort() {
        contactList.sort { (cntctA, cntctB) -> Bool in
            cntctA.name < cntctB.name
        }
    }


    static func numberOfContacts() -> Int {
        return ContactListService.contactList.count
    }

    /**
         - Returns: Array of contacts
    */
    static func getContacts() -> [Contact] {
        return ContactListService.contactList
    }

    /**
        - Parameters:
            - index: Index of the contact
        
         - Returns: Contact at given index
    */
    static func getContact(index: Int) -> Contact {
        return ContactListService.contactList[index]
    }

    
    /**
         - Returns: Array of contacts with a public key
    */
    static func getPublicKeyContacts() -> [Contact] {
        var cntcts: [Contact] = []
        for cntct in ContactListService.contactList where cntct.key.isPublic {
            cntcts.append(cntct)
        }
        return cntcts
    }
    
    /**
         - Returns: Array of contacts with a private key
    */
    static func getPrivateKeyContacts() -> [Contact] {
        var cntcts: [Contact] = []
        for cntct in ContactListService.contactList where cntct.key.isSecret {
            cntcts.append(cntct)
        }
        return cntcts
    }


    /**
        - Parameters:
            - contact: Contact

         - Returns: Array index of contact, -1 if not successful
    */
    static func getIndex(contact: Contact) -> Int {
        return ContactListService.contactList.firstIndex { (cntct) -> Bool in
            cntct.email == contact.email
            } ?? -1
    }


    /**
         Adds a contact to persistent and in-memory storage

         - Parameters:
            - name: Name of the contact
            - email: Unique and valid email address
            - key: PGP (public and/or private) key

         - Returns: True, if successful
    */
    static func addContact(name: String, email: String, key: Key) -> Bool {
        /* Check if contact with this email address already exists */
        for cntct in ContactListService.contactList where (cntct.email == email) {
            return false
        }
        
        /* Create new contact instance */
        let contact = Contact(context: PersistenceService.context)
        contact.name = name
        contact.email = email
        do {
            let keyData = try key.export() as NSData
            guard (keyData.length > 0) else { return false }
            contact.keyData = keyData
        } catch {
            print("Failed to save Key as Data!")
            return false
        }
            
        /* Add contact to in-memory and persistent data storage */
        ContactListService.contactList.append(contact)
        ContactListService.sort()
        PersistenceService.save()
        
        /* Notify observers about change */
        NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange,
                                        object: nil
        )
        
        return true
    }


    /**
         Naive approach to editing a contact

         - Parameters:
            - cntct: Contact
            - newName: New name of the contact
            - newEmail: New email address of the contact

         - Returns: True, if successful
    */
    static func editContact(contact: Contact, newName: String, newEmail: String) -> Bool {
        /* Check if contact with this email address already exists */
        for cntct in ContactListService.contactList where (cntct.email == newEmail && contact.email != newEmail) {
            return false
        }
        
        let cntctIdx = self.getIndex(contact: contact)
        let oldKey = contact.key
        self.removeContact(index: cntctIdx)
        
        let success = self.addContact(name: newName, email: newEmail, key: oldKey)
        
        /* Delete temporary data (selected keys) */
        EncryptionTableViewController.encryptionContacts = [Contact]()
        NotificationCenter.default.post(name: Constants.NotificationNames.publicKeySelectionChange,
                                        object: nil)

        DecryptionTableViewController.decryptionContact = nil
        NotificationCenter.default.post(name: Constants.NotificationNames.privateKeySelectionChange,
        object: nil)
        
        return success
    }


    static func removeContact(index: Int) {
        /* Delete contact from persistent data */
        PersistenceService.context.delete(contactList[index])
        PersistenceService.save()
        
        /* Delete contact from in-memory data */
        ContactListService.contactList.remove(at: index)
        
        /* Notify observers about change */
        NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange,
                                        object: nil
        )
    }


    /**
         Deletes all persistent and in-memory data
    */
    static func deleteAllData() {

        /* Delete in-memory and persistent data */
        for cntct in contactList {
            PersistenceService.context.delete(cntct)
        }
        PersistenceService.save()
        self.contactList = []
        NotificationCenter.default.post(name: Constants.NotificationNames.contactListChange,
        object: nil)

        /* Delete temporary data (selected keys) */
        EncryptionTableViewController.encryptionContacts = [Contact]()
        NotificationCenter.default.post(name: Constants.NotificationNames.publicKeySelectionChange,
                                        object: nil)

        DecryptionTableViewController.decryptionContact = nil
        NotificationCenter.default.post(name: Constants.NotificationNames.privateKeySelectionChange,
        object: nil)
    }


    /**
         Removes contacts with PGP keys that are not supported
    */
    static func cleanUp() -> Int{
        var count = 0
        for cntct in ContactListService.contactList where (!cntct.key.isPublic && !cntct.key.isSecret) {
            let cntctIdx = self.getIndex(contact: cntct)
            self.removeContact(index: cntctIdx)
            count += 1
        }
        return count
    }
}
