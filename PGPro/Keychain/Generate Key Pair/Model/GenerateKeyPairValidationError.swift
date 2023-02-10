//
//  GenerateKeyPairValidationError.swift
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

enum GenerateKeyPairError: Error, CustomStringConvertible {
    case nameEmpty
    case emailAddressEmpty
    case emailAddressInvalid
    case passphraseEmpty
    case passphraseConfirmEmpty
    case passphraseMismatch
    case importFailed

    var description: String {
        switch self {
            case .nameEmpty:
                return "Name cannot be empty."
            case .emailAddressEmpty:
                return "Email address cannot be empty."
            case .emailAddressInvalid:
                return "Email address is invalid."
            case .passphraseEmpty:
                return "Passphrase cannot be empty."
            case .passphraseConfirmEmpty:
                return "Please confirm the passphrase."
            case .passphraseMismatch:
                return "Passphrases do not match."
            case .importFailed:
                return "Failed to import key."
        }
    }
}
