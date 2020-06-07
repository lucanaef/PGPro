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
import SwiftTryCatch

class VerifyingKeyserverInterface {

    enum VKIError: Error {
        case keyNotFound
        case noConnection
        case serverDatabaseMaintenance
        case rateLimiting
        case invalidFormat
        case invalidResponse
        case keyNotSupported
    }

    private init() {}

    static private var baseURL = "https://keys.openpgp.org"

    static func getByEmail(email: String, completion: @escaping((Result<[Key], VKIError>) -> Void)) {

        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            completion(.failure(.invalidFormat))
            return
        }
        let urlString = baseURL + "/vks/v1/by-email/" + encodedEmail
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidFormat))
            return
        }

        // Send GET request to keyserver and handle response
        GET(url: url, completion: completion)
    }

    static func getByFingerprint(fingerprint: String, completion: @escaping((Result<[Key], VKIError>) -> Void)) {

        let formattedFingerprint = fingerprint.components(separatedBy: .whitespaces).joined()
        Log.d(formattedFingerprint)
        let urlString = baseURL + "/vks/v1/by-fingerprint/" + formattedFingerprint
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidFormat))
            return
        }

        // Send GET request to keyserver and handle response
        GET(url: url, completion: completion)
    }

    static func getByKeyID(keyID: String, completion: @escaping((Result<[Key], VKIError>) -> Void)) {

        let formattedKey = keyID.components(separatedBy: .whitespaces).joined()
        let urlString = baseURL + "/vks/v1/by-keyid/" + formattedKey
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidFormat))
            return
        }

        // Send GET request to keyserver and handle response
        GET(url: url, completion: completion)
    }

    static private func GET(url: URL, completion: @escaping((Result<[Key], VKIError>) -> Void)) {

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
            } else if (httpResponse.statusCode == 429) {
                completion(.failure(.rateLimiting))
                return
            } else if (httpResponse.statusCode == 503) {
                completion(.failure(.serverDatabaseMaintenance))
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
