//
//  WebKeyDirectoryService.swift
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
import SwiftTryCatch

class WebKeyDirectoryService {

    enum WKDError: Error {
        case keyNotFound
        case noConnection
        case invalidFormat
        case invalidResponse
        case keyNotSupported
    }

    enum WKDMethod {
        case advanced
        case direct
    }

    private init() {}

    static func getByEmail(email: String, method: WKDMethod = .advanced, completion: @escaping((Result<[Key], WKDError>) -> Void)) {
        if let advancedURL = constructURL(email: email, method: method) {
            GET(url: advancedURL, completion: completion)
        }
    }

    private static func constructURL(email: String, method: WKDMethod) -> URL? {
        if !email.isValidEmail() {
            return nil
        }

        // Dissect email address
        let emailComponents = email.components(separatedBy: "@")
        let local = emailComponents[0]
        let domain = emailComponents[1]

        // SHA1-hash and zBase32-encode local part of email address
        guard let hashedLocal = local.insecureSHA1Hash() else {
            return nil
        }
        guard let encodedLocal = Data(hexString: hashedLocal)?.zBase32Encoded else {
            return nil
        }

        // Construct URL based on chosen methode
        switch (method) {
        case .advanced:
            return URL(string: "https://openpgpkey." + domain + "/.well-known/openpgpkey/" + domain + "/hu/" + encodedLocal)
        case .direct:
            return URL(string: "https://" + domain + "/.well-known/openpgpkey/hu/" + encodedLocal)
        }
    }

    static private func GET(url: URL, completion: @escaping((Result<[Key], WKDError>) -> Void)) {

        URLSession.shared.dataTask(with: url) { data, res, error in
            if (error != nil) {
                completion(.failure(.noConnection))
                return
            }
            guard let httpResponse = res as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            /// Handle critical HTTP status codes
            if (httpResponse.statusCode == 404) {
                completion(.failure(.keyNotFound))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            /// Try to read keys from data
            var readKeys: [Key] = []
            SwiftTryCatch.try({
                do {
                    readKeys = try ObjectivePGP.readKeys(from: data)
                } catch {
                    completion(.failure(.invalidResponse))
                    return
                }
            }, catch: { (error) in
                completion(.failure(.keyNotSupported))
                return
                }, finallyBlock: {
            })

            if (readKeys.isEmpty) {
                completion(.failure(.keyNotFound))
                return
            }

            completion(.success(readKeys))

        }.resume()

    }

}
