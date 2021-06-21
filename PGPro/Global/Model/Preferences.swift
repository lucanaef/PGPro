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

class Preferences {

    enum UserDefaultsKeys {
        static var numRatings = "numRatings"
        static var launchedBefore = "launchedBefore"
        static var mailIntegration = "preference.mailIntegration"
        static var biometricAuthentication = "preference.biometricAuthentication"
        static var yubikey = "preference.yubikey"
    }

    static func setToDefault() {
        UserDefaults.standard.set(true,  forKey: UserDefaultsKeys.launchedBefore)
        UserDefaults.standard.set(0,     forKey: UserDefaultsKeys.numRatings)
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.mailIntegration)
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.biometricAuthentication)
        UserDefaults.standard.set(true,  forKey: UserDefaultsKeys.yubikey)
    }

    static var mailIntegrationEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.mailIntegration)
        }
    }

    static var biometricAuthentication: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricAuthentication)
        }
    }

    static var yubikey: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.biometricAuthentication)
        }
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
