//
//  KeyserverSearchViewModel.swift
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

class KeyserverSearchViewModel: ObservableObject {
    @Published var results: KeyserverSearchResults = []
    @Published var isSearching = false

    @MainActor
    func search(for keyword: String) async {
        isSearching = true
        // Clear previous search results
        results = []

        // Web Key Directory
        if keyword.isValidEmail {
            let wkdResults = await WebKeyDirectory.search(for: keyword)
            results.append(contentsOf: wkdResults.map({ KeyserverSearchResult(key: $0, origin: .webKeyDirectory) }))
        }

        // keys.openpgp.org
        let openpgporgKeyServer = VerifyingKeyserver(url: URL(string: "https://keys.openpgp.org")!)
        let openpgporgResults = await openpgporgKeyServer.search(for: keyword)
        results.append(contentsOf: openpgporgResults.map({ KeyserverSearchResult(key: $0, origin: .openpgpdotorg) }))

        // api.protonmail.ch
        if keyword.isValidEmail {
            let protonMailAPI = ProtonMailAPI(url: URL(string: "https://api.protonmail.ch")!)
            let protonMailAPIResults = await protonMailAPI.search(for: keyword)
            results.append(contentsOf: protonMailAPIResults.map({ KeyserverSearchResult(key: $0, origin: .protonmailAPI) }))
        }

        isSearching = false
    }
}
