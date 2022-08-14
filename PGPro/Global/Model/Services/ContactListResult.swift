//
//  ContactListResult.swift
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
import SPAlert
import UIKit

/// Return type when adding keys to the contact list
struct ContactListResult {
    /// Number of successfuly added contacts
    var successful: Int
    /// Number omitted contacts due to unsupported keys
    var unsupported: Int
    /// Number omitted contacts due to duplicate email addresses
    var duplicates: Int
}

extension UIViewController {

    func alert(_ result: ContactListResult, completion: (() -> Void)? = nil) {

        var title: String
        var message: String
        var present: SPAlertIconPreset
        var haptic: SPAlertHaptic

        if result.successful > 0 {
            title = "Success!"
            message = "\(result.successful) key\(result.successful == 1 ? "" : "s") imported"
            present = .done
            haptic = .success
        } else {
            title = "Import failed!"
            message = "Failed to import key"
            present = .error
            haptic = .error
        }

        let newline: String = "\n"
        if result.unsupported > 0 {
            message.append(contentsOf: "\(newline)\(result.unsupported) unsupported key\(result.unsupported == 1 ? "" : "s") skipped")
        }
        if result.duplicates > 0 {
            message.append(contentsOf: "\(newline)\(result.duplicates) duplicate key\(result.duplicates == 1 ? "" : "s") skipped")
        }

        let alertView = SPAlertView(title: title, message: message, preset: present)
        alertView.duration = 7.0

        alertView.present(haptic: haptic, completion: completion)
    }

}
