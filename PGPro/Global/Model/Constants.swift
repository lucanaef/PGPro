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
import StoreKit
import MessageUI

enum Constants {

    enum KeyType {
        case publicKey
        case privateKey
        case both
        case none
    }

    // MARK: - Global Constants
    struct PGPro {
        private init() {}

        static let appID = "1481696997"

        static var version: String? {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        }

        static var numRatings: Int {
            // try to get current number and update cached value
            iTunesInterface.requestJSON(localizedFor: User.countryCode) { result in
                switch result {
                    case .failure(let error):
                        Log.e(error)
                    case .success(let data):
                        if let data = data[0] as? [String: Any] {
                            if let userRatingCount = data["userRatingCountForCurrentVersion"] {
                                let numRatings = userRatingCount as? Int
                                if let numRatings = numRatings {
                                    Preferences.numRatings = numRatings
                                }
                            }
                        }
                }
            }
            // return cached value
            return Preferences.numRatings
        }
        
    }

    // MARK: - User Constants
    struct User {
        private init() {}

        static var countryCode: IsoCountryInfo? {
            if let alpha3CountryCode = SKPaymentQueue.default().storefront?.countryCode {
                return IsoCountryCodes.find(key: alpha3CountryCode)
            } else {
                return nil
            }
        }

        static var canSendMail: Bool {
            MFMailComposeViewController.canSendMail()
        }

        static var canUseBiometrics: Bool {
            AuthenticationService.faceIDAvailable || AuthenticationService.touchIDAvailable
        }

    }


    // MARK: - Notification Names
    enum NotificationNames {
        static var contactListChange = Notification.Name(rawValue: "pgpro.contactListChange")
    }

}
