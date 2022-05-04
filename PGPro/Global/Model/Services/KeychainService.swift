//
//  KeychainService.swift
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

import Security
import Foundation

enum KeychainError: Error {
    // Attempted read for an item that does not exist.
    case itemNotFound

    case invalidItemFormat

    // Any operation result status than errSecSuccess
    case unexpectedStatus(OSStatus)
}

/**
 Custom keychain wrapper class heavily inspired by https://www.advancedswift.com/secure-private-data-keychain-swift/
 */
class KeychainService {

    private init() {}

    private static var prefix = "app.pgpro"

    public static func set(_ value: String, forKey key: String) throws {
        let query: [String: AnyObject] = [
            kSecClass               as String: kSecClassGenericPassword,
            kSecAttrAccessible      as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable  as String: kCFBooleanFalse,
            kSecAttrService         as String: Data(KeychainService.prefix.utf8) as AnyObject,
            kSecAttrAccount         as String: Data(key.utf8) as AnyObject,
            kSecValueData           as String: Data(value.utf8) as AnyObject
        ]

        // SecItemAdd attempts to add the item identified by the query to keychain
        let status = SecItemAdd(query as CFDictionary, nil)

        // errSecDuplicateItem is a special case where the item identified by the query already exists.
        if status == errSecDuplicateItem {
            do {
                try update(value, forKey: key)
            } catch let error {
                throw error
            }
        }

        // Any status other than errSecSuccess indicates the save operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private static func update(_ value: String, forKey key: String) throws {
        let query: [String: AnyObject] = [
            kSecClass               as String: kSecClassGenericPassword,
            kSecAttrAccessible      as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable  as String: kCFBooleanFalse,
            kSecAttrService         as String: Data(KeychainService.prefix.utf8) as AnyObject,
            kSecAttrAccount         as String: Data(key.utf8) as AnyObject
        ]

        // attributes is passed to SecItemUpdate with kSecValueData as the updated item value
        let attributes: [String: AnyObject] = [
            kSecValueData as String: Data(value.utf8) as AnyObject
        ]

        // SecItemUpdate attempts to update the item identified by query, overriding the previous value
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        // errSecItemNotFound is a special status indicating the item to update does not exist.
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        // Any status other than errSecSuccess indicates the update operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public static func get(_ key: String) throws -> String {
        let query: [String: AnyObject] = [
            kSecClass           as String: kSecClassGenericPassword,
            kSecAttrService     as String: Data(KeychainService.prefix.utf8) as AnyObject,
            kSecAttrAccount     as String: Data(key.utf8) as AnyObject,

            // kSecMatchLimitOne indicates keychain should read only the most recent item matching this query
            kSecMatchLimit as String: kSecMatchLimitOne,

            // kSecReturnData is set to kCFBooleanTrue in order to retrieve the data for the item
            kSecReturnData as String: kCFBooleanTrue
        ]

        // SecItemCopyMatching will attempt to copy the item identified by query to the reference itemCopy
        var itemCopy: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)

        // errSecItemNotFound is a special status indicating the read item does not exist.
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        // Any status other than errSecSuccess indicates the read operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }

        guard let valueData = itemCopy as? Data else {
            throw KeychainError.invalidItemFormat
        }

        guard let value = String(data: valueData, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        return value
    }

    public static func delete(_ key: String) throws {
        let query: [String: AnyObject] = [
            kSecClass           as String: kSecClassGenericPassword,
            kSecAttrService     as String: Data(KeychainService.prefix.utf8) as AnyObject,
            kSecAttrAccount     as String: Data(key.utf8) as AnyObject
        ]

        // SecItemDelete attempts to perform a delete operation for the item identified by query.
        let status = SecItemDelete(query as CFDictionary)

        // Any status other than errSecSuccess indicates the delete operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

}
