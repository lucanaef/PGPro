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

    static func setToDefault() {
        UserDefaults.standard.set(true,  forKey: Constants.UserDefaultsKeys.launchedBefore)
        UserDefaults.standard.set(0,     forKey: Constants.UserDefaultsKeys.numRatings)
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.mailIntegration)
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.attachPublicKey)
    }

    static var mailIntegrationEnabled: Bool {
        return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.mailIntegration)
    }

    static var attachPublicKey: Bool {
        return UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.attachPublicKey)
    }


}
