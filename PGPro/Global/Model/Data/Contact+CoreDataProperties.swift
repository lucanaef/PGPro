//
//  Contact+CoreDataProperties.swift
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
import SwiftTryCatch

extension Contact {

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Contact> {
        return NSFetchRequest<Contact>(entityName: "Contact")
    }

    @NSManaged public var name: String
    @NSManaged public var email: String
    @NSManaged public var keyData: NSData

    var userID: String {
        return "\(name) <\(email)>"
    }

    public override var description: String { userID }

    var keyRequiresPassphrase: Bool {
        return key.isEncryptedWithPassword
    }

    var key: Key {
        var keys = [Key(secretKey: nil, publicKey: nil)]

        // Hacky solution to recover from https://github.com/krzyzanowskim/ObjectivePGP/issues/168
        SwiftTryCatch.try({
            do {
                keys = try ObjectivePGP.readKeys(from: self.keyData as Data)
            } catch {
                Log.e(error)
            }
        }, catch: { (error) in
            Log.e("Error info: \(String(describing: error))")
            return
            }, finallyBlock: {
        })

        return keys[0]
    }

    func getArmoredKey(as type: PGPArmorType) -> String? {
        return try? Armor.armored(key.export(), as: type)
    }

}


extension Contact: Comparable {

    public static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.userID == rhs.userID
    }

    public static func < (lhs: Contact, rhs: Contact) -> Bool {
        if (lhs.name != rhs.name) {
            return lhs.name < rhs.name
        } else {
            return lhs.email < rhs.email
        }
    }

}
