//
//  RouterPath.swift
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
import SwiftUI

class RouterPath: ObservableObject {
    // MARK: - Tab View State
    enum Tab: Hashable {
        case encryption
        case decryption
        case keychain
        case settings
    }

    @Published var selectedTab: Tab = .decryption

    // MARK: - Tab: Encryption
    @Published public var encryptionTab: [EncryptionTabPath] = []

    enum EncryptionTabPath: Hashable {
        case recipients
        case signatures
    }

    // MARK: - Tab: Decryption
    @Published public var decryptionTab: [DecryptionTabPath] = []

    enum DecryptionTabPath: Hashable {
        case keyPicker
        case result(result: OpenPGP.DecryptionResult)
    }

    // MARK: - Tab: Keychain

    // MARK: - Tab: Settings

}
