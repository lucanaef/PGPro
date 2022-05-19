//
//  Preferences.swift
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
import ThirdPartyMailer

class Preferences {

    static private let defaults = UserDefaults.standard

    enum UserDefaultsKeys {
        static var numRatings = "numRatings"
        static var launchedBefore = "launchedBefore"
        static var mailIntegration = "preference.mailIntegration"
        static var mailIntegrationClient = "preference.mailIntegrationClient"
        static var biometricAuthentication = "preference.biometricAuthentication"
        static var reviewWorthyActions = "reviewWorthyActionCount"
    }

    static func setToDefault() {
        defaults.set(true, forKey: UserDefaultsKeys.launchedBefore)
        defaults.set(0, forKey: UserDefaultsKeys.numRatings)
        defaults.set(false, forKey: UserDefaultsKeys.mailIntegration)
        defaults.set(false, forKey: UserDefaultsKeys.biometricAuthentication)
    }

    static var mailIntegrationEnabled: Bool {
        get {
            MailIntegration.isEnabled
        }
        set {
            MailIntegration.isEnabled = newValue
        }
    }

    static var mailIntegrationClientName: String? {
        get {
            defaults.string(forKey: Preferences.UserDefaultsKeys.mailIntegrationClient)
        }
        set {
            defaults.set(newValue, forKey: Preferences.UserDefaultsKeys.mailIntegrationClient)
        }
    }

    static var biometricAuthentication: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricAuthentication)
    }

    static var numRatings: Int {
        get {
            UserDefaults.standard.integer(forKey: UserDefaultsKeys.numRatings)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.numRatings)
        }
    }

}
