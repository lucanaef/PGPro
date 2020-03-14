//
//  VerifyingKeyserverInterface.swift
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

class VerifyingKeyserverInterface {

    private init() {}

    static func getByEmail(email: String) {

        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard encodedEmail != nil else { return }

        let urlString = "https://keys.openpgp.org/vks/v1/by-email/" + encodedEmail!
        print(urlString)

        if let url = URL(string: urlString) {

            URLSession.shared.dataTask(with: url) { data, res, error in
                if let data = data {
                    do {
                        let keys = try ObjectivePGP.readKeys(from: data)
                        print(keys)
                    } catch {}
                }
            }.resume()
        }
    }

}
