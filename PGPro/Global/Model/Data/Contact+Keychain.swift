//
//  Contact+Keychain.swift
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

extension Contact {

    enum ContactKeychainError: Error {
        case emptyKeyPackets
        case keyHasNoPassphrase
    }

    func setPassphrase(to passphrase: String) throws {
        guard keyRequiresPassphrase else {
            throw ContactKeychainError.keyHasNoPassphrase
        }
        guard let fingerprint = self.keyFingerprint else {
            throw ContactKeychainError.emptyKeyPackets
        }
        do {
            try KeychainService.set(passphrase, forKey: fingerprint)
        } catch (let error) {
            throw error
        }
    }

    func updatePassphrase(to passhrase: String) throws {
        guard keyRequiresPassphrase else {
            throw ContactKeychainError.keyHasNoPassphrase
        }
        guard let fingerprint = self.keyFingerprint else {
            throw ContactKeychainError.emptyKeyPackets
        }
        do {
            try KeychainService.update(passhrase, forKey: fingerprint)
        } catch (let error) {
            throw error
        }
    }

    func getPassphrase() -> Result<String, Error> {
        guard keyRequiresPassphrase else {
            return .failure(ContactKeychainError.keyHasNoPassphrase)
        }
        guard let fingerprint = self.keyFingerprint else {
            return .failure(ContactKeychainError.emptyKeyPackets)
        }
        do {
            let passphrase = try KeychainService.get(fingerprint)
            return .success(passphrase)
        } catch (let error) {
            return .failure(error)
        }

    }

    func deletePassphrase() throws {
        guard keyRequiresPassphrase else {
            throw ContactKeychainError.keyHasNoPassphrase
        }
        guard let fingerprint = self.keyFingerprint else {
            throw ContactKeychainError.emptyKeyPackets
        }
        do {
            try KeychainService.delete(fingerprint)
        } catch (let error) {
            throw error
        }
    }

}
