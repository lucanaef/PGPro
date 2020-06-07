//
//  KeyConstructionService.swift
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
import SwiftTryCatch

class KeyConstructionService {

    enum KeyConstructionError: Error {
        case keyNotSupported
        case invalidFormat
        case noConnection
    }

    private init() {}

    static func fromString(keyString: String) throws -> [Key] {
        guard let asciiKeyData = keyString.data(using: .ascii) else { throw KeyConstructionError.invalidFormat }

        var readKeys: [Key] = []
        SwiftTryCatch.try({
            do {
                readKeys = try ObjectivePGP.readKeys(from: asciiKeyData)
            } catch let error {
                Log.e("Error info: \(error)")
            }
        }, catch: { (error) in
            Log.e("Error info: \(String(describing: error))")
            }, finallyBlock: {
        })
        return readKeys
    }

    static func fromFile(fileURL: URL) throws -> [Key] {
        var readKeys: [Key] = []
        SwiftTryCatch.try({
            do {
                readKeys = try ObjectivePGP.readKeys(fromPath: fileURL.path)
            } catch let error {
                Log.e("Error info: \(error)")
            }
        }, catch: { (error) in
            Log.e("Error info: \(String(describing: error))")
            }, finallyBlock: {
        })
        return readKeys
    }

}
