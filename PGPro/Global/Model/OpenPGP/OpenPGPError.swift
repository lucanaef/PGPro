//
//  OpenPGPError.swift
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

enum OpenPGPError: Error, CustomStringConvertible {
    case emptyMessage
    case invalidMessage
    case requiresPassphrase
    case wrongPassphrase
    case frameworkError(_ error: Error)
    case failedEncryption(description: String)
    case failedDecryption(description: String)

    var description: String {
        switch self {
            case .emptyMessage:
                return "Message can't be empty."
            case .invalidMessage:
                return "Message invalid."
            case .requiresPassphrase:
                return "Missing passphrase required."
            case .wrongPassphrase:
                return "Wrong passphrase."
            case .frameworkError(let error):
                return "Framework Error: \(error.localizedDescription)"
            case .failedEncryption(let description):
                return "Encryption failed. \(description)"
            case .failedDecryption(let description):
                return "Decryption failed. \(description)"
        }
    }
}
