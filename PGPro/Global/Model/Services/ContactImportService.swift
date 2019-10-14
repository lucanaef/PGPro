//
//  ContactImportService.swift
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
import UIKit
import Contacts

class ContactImportService {
    
    static private var store = CNContactStore()
    
    private init() {}
    
    /**
        Imports all contacts from the address book to the app if a key can be found on a keyserver

         - Returns: Number of successfully imported contacts or -1 on network error
    */
    static func importContacts() -> Int {
        /// Ask for permission
        ContactImportService.store.requestAccess(for: .contacts) { (success, error) in
            if let error = error {
                print("Failed to request access to contacts: ", error)
                return
            }
            
            if !success {
                print("Access to Contacts not granted!")
                return
            }
        }
        
        let requestedKeys = [CNContactGivenNameKey, CNContactMiddleNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: requestedKeys)
        
        do {
            var addedContacts = 0
            
            try ContactImportService.store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stopPointer) in
                var middleName = " "
                if contact.middleName != "" {
                    middleName = " " + contact.middleName + " "
                }
                let fullName = contact.givenName + middleName + contact.familyName
                
                for email in contact.emailAddresses {
                    let formattedEmail = email.value.replacingOccurrences(of: " ", with: "") as String
                                        
                    if ContactListService.addContactFromKeyserver(name: fullName, email: formattedEmail) {
                        addedContacts += 1
                    }
                }
            })
            
            return addedContacts
            
        } catch let error {
            print("Failed to enumerate contacts: ", error)
        }
        
        return 0
        
    }
    
}
