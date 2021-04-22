//
//  iTunesInterface.swift
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

class iTunesInterface {

    private init() {}

    enum apiError: Error {
        case networkError
        case invalidResponse
        case parsingError
        case otherError
    }

    static func requestJSON(localizedFor country: IsoCountryInfo? = nil, completion: @escaping((Result<NSArray, apiError>) -> Void)) {

        var baseURL = "https://itunes.apple.com/lookup?id=\(Constants.PGPro.appID)"
        if let countryCode = country?.alpha2 {
            baseURL += "&country=\(countryCode)"
        }

        guard let url = URL(string: baseURL) else {
            completion(.failure(apiError.otherError))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if (error != nil) {
                completion(.failure(.networkError))
                return
            }

            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let results = jsonResponse["results"] as? NSArray {
                        completion(.success(results))
                        return
                    }
                } else {
                    completion(.failure(.parsingError))
                    return
                }
            } catch {
                completion(.failure(.parsingError))
                return
            }
        }.resume()

    }

}
