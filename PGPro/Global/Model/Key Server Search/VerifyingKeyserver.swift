//
//  VerifyingKeyserver.swift
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

class VerifyingKeyserver {
    private(set) var baseURL: URL

    // MARK: - Public

    init(url: URL) {
        self.baseURL = url
    }

    func search(for string: String) async -> [Key] {
        var results: Set<Key> = Set()

        for scheme in VKIScheme.allCases {
            if let url = constructURL(for: string, scheme: scheme) {
                let keys = await URLSession.shared.keys(from: url)
                results.formUnion(keys)
            }
        }

        return Array(results)
    }

    // MARK: - Private

    private enum VKIScheme: CaseIterable {
        case fingerprint
        case keyID
        case email
    }

    private func constructURL(for string: String, scheme: VKIScheme) -> URL? {
        switch scheme {
        case .fingerprint:
            let joinedFingerprint = string.components(separatedBy: .whitespaces).joined()
            return baseURL.appending(component: "/vks/v1/by-fingerprint/").appending(component: joinedFingerprint)

        case .keyID:
            let joinedKeyID = string.components(separatedBy: .whitespaces).joined()
            return baseURL.appending(component: "/vks/v1/by-keyid/").appending(component: joinedKeyID)

        case .email:
            guard string.isValidEmail else {
                return nil
            }
            return baseURL.appending(component: "/vks/v1/by-email/").appending(component: string)
        }
    }
}
