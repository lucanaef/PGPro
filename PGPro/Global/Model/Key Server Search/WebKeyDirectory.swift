//
//  WebKeyDirectory.swift
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

class WebKeyDirectory {
    // MARK: - Public

    static func search(for email: String) async -> [Key] {
        var results: Set<Key> = Set()

        for method in WKDMethod.allCases {
            if let url = constructURL(email: email, method: method) {
                let keys = await URLSession.shared.keys(from: url)
                results.formUnion(keys)
            }
        }

        return Array(results)
    }

    // MARK: - Private

    private init() {}

    private enum WKDMethod: CaseIterable {
        case advanced
        case direct
    }

    private static func constructURL(email: String, method: WKDMethod) -> URL? {
        guard email.isValidEmail else {
            return nil
        }

        // Dissect email address
        let emailComponents = email.components(separatedBy: "@")
        let local = emailComponents[0]
        let domain = emailComponents[1]

        // SHA1-hash and zBase32-encode local part of email address
        guard let hashedLocal = local.SHA1() else {
            return nil
        }
        guard let encodedLocal = Data(hexString: hashedLocal)?.zBase32Encoded else {
            return nil
        }

        // Construct URL based on chosen methode
        switch method {
            case .advanced:
                return URL(string: "https://openpgpkey." + domain + "/.well-known/openpgpkey/" + domain + "/hu/" + encodedLocal)

            case .direct:
                return URL(string: "https://" + domain + "/.well-known/openpgpkey/hu/" + encodedLocal)
        }
    }
}
