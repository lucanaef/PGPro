//
//  AppStoreReviewService.swift
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

class AppStoreReviewService {

    private init() {}

    static var minimumReviewWorthyActionCount = 10
    static let reviewWorthyActionKey = "reviewWorthyActionCount"

    static func incrementReviewWorthyActionCount() {
        let defaults = UserDefaults.standard

        var actionCount = defaults.integer(forKey: reviewWorthyActionKey)
        actionCount += 1
        defaults.set(actionCount, forKey: reviewWorthyActionKey)
    }

    static func requestReviewIfAppropriate() {
        let defaults = UserDefaults.standard

        let actionCount = defaults.integer(forKey: reviewWorthyActionKey)
        if (actionCount >= minimumReviewWorthyActionCount) {
            SKStoreReviewController.requestReview()
            minimumReviewWorthyActionCount += 10
            defaults.set(0, forKey: reviewWorthyActionKey)
        }
    }


}
