//
//  Contact+Comparable.swift
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

extension Contact: Comparable {

    public static func == (lhs: Contact, rhs: Contact) -> Bool {
        (lhs.key == rhs.key) || ((lhs.key.keyID == rhs.key.keyID) && (lhs.key.isPublic == rhs.key.isPublic) && (lhs.key.isSecret == rhs.key.isSecret))
    }

    public static func < (lhs: Contact, rhs: Contact) -> Bool {
        if lhs.name != rhs.name {
            return lhs.name < rhs.name
        } else {
            return lhs.email < rhs.email
        }
    }

}
