//
//  ProtonMailAPI.swift
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

class ProtonMailAPI {
    // MARK: - Public

    private(set) var baseURL: URL

    init(url: URL) {
        self.baseURL = url
    }

    func search(for email: String) async -> [Key] {
        var results: Set<Key> = Set()

        if let url = constructURL(email: email) {
            let keys = await URLSession.shared.keys(from: url)
            results.formUnion(keys)
        }

        return Array(results)
    }

    // MARK: - Private

    private func constructURL(email: String) -> URL? {
        guard email.isValidEmail else { return nil }

        return URL(string: "\(baseURL.absoluteString)/pks/lookup?op=get&search=\(email)")
    }
}
