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

extension Contact {

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Contact> {
        return NSFetchRequest<Contact>(entityName: "Contact")
    }

    @NSManaged public var email: String
    @NSManaged public var keyData: NSData
    @NSManaged public var name: String

    public var key: Key {
        do {
            let keys = try ObjectivePGP.readKeys(from: keyData as Data)
            return keys[0]
        } catch {
            return Key(secretKey: nil, publicKey: nil)
        }
    }

    public var userID: String {
        let userid = self.name + " <" + self.email + ">"
        return userid
    }

}
