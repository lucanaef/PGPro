//
//  Contact+OpenPGP.swift
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

extension Contact {
    var primaryKey: Key? {
        do {
            return try OpenPGP.key(from: self.keyData as Data)
        } catch {
            Log.e(error)
            return nil
        }
    }

    var fingerprint: String? {
        if let pubKey = primaryKey?.publicKey {
            return pubKey.fingerprint.description()
        } else if let privKey = primaryKey?.secretKey {
            return privKey.fingerprint.description()
        } else {
            return nil
        }
    }

    var isPublicKey: Bool {
        return primaryKey?.isPublic ?? false
    }

    var isPrivateKey: Bool {
        return primaryKey?.isSecret ?? false
    }

    var requiresPassphrase: Bool {
        guard let key = primaryKey, key.isSecret else { return false }
        return key.isEncryptedWithPassword
    }

    var expirationDateString: String? {
        if let date = primaryKey?.expirationDate {
            return ISO8601DateFormatter.string(from: date, timeZone: .autoupdatingCurrent, formatOptions: .withFullDate)
        } else {
            return nil
        }
    }

    func exportKey(of type: PGPKeyType) -> String? {
        switch type {
            case .public:
                do {
                    if let publicKeyData = try primaryKey?.export(keyType: .public) {
                        return Armor.armored(publicKeyData, as: .publicKey)
                    } else {
                        return nil
                    }
                } catch {
                    Log.e(error)
                    return nil
                }

            case .secret:
                do {
                    if let publicKeyData = try primaryKey?.export(keyType: .public),
                        let privateKeyData = try primaryKey?.export(keyType: .secret) {
                        return Armor.armored(publicKeyData, as: .publicKey) + Armor.armored(privateKeyData, as: .secretKey)
                    } else {
                        return nil
                    }
                } catch {
                    Log.e(error)
                    return nil
                }

            case .unknown:
                return nil
            @unknown default:
                return nil
        }
    }
}
