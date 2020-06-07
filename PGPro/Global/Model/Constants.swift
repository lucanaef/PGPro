//
//  Constants.swift
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

enum Constants {

    enum KeyType {
        case publicKey
        case privateKey
        case both
        case none
    }

    // MARK - Global PGPro Constants
    struct PGPro {
        static let appID = "1481696997"

        static var version: String {
            let vrsn = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            if let vrsn = vrsn as? String {
                return vrsn
            } else {
                return ""
            }
        }

        static var numRatings: Int {
            // try to get current number and update cached value
            iTunesInterface.requestJSON { result in
                switch result {
                    case .failure(let error):
                        Log.e(error)
                    case .success(let data):
                        if let data = data[0] as? [String: Any] {
                            if let numRatings = data["userRatingCountForCurrentVersion"] {
                                UserDefaults.standard.set(numRatings, forKey: "numRatings")
                            }
                        }
                }
            }

            // return cached value
            return UserDefaults.standard.integer(forKey: "numRatings")
        }
        
    }

    // MARK - Notification Names
    enum NotificationNames {
        static var contactListChange = Notification.Name(rawValue: "pgpro.contactListChange")
    }

    static var licenses: [License] = [
        License(for: "PGPro",
                at: URL(string: "https://github.com/lucanaef/PGPro/blob/master/LICENSE")!),
        License(for: "ObjectivePGP",
                describedBy: "OpenPGP library for iOS and macOS",
                at: URL(string: "https://objectivepgp.com/LICENSE.txt")!),
        License(for: "OpenSSL",
                describedBy: "Cryptography and SSL/TLS Toolkit",
                at: URL(string: "https://www.openssl.org/source/license-openssl-ssleay.txt")!),
        License(for: "SwiftTryCatch",
                at: URL(string: "https://github.com/seanparsons/SwiftTryCatch/blob/master/LICENSE")!),
        License(for: "Navajo-Swift",
                describedBy: "Password Validator & Strength Evaluator",
                at: URL(string: "https://github.com/jasonnam/Navajo-Swift/blob/master/LICENSE")!),
        License(for: "Swiftlogger",
                describedBy: "Tiny Logger in Swift",
                at: URL(string: "https://github.com/sauvikdolui/swiftlogger/blob/master/LICENSE")!)

    ]

}
