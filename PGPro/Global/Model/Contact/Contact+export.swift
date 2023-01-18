//
//  Contact+export.swift
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

import CoreData
import Foundation
import ObjectivePGP

extension Contact {
    private static let moc = DataController.shared.container.viewContext

    enum ContactExportError: LocalizedError {
        case fetchRequestFailed

        var errorDescription: String {
            switch self {
            case .fetchRequestFailed:
                return "Failed to build fetchRequest."
            }
        }
    }

    static func exportAll() -> Result<URL, Error> {
        if let fetchRequest = Contact.fetchRequest() as? NSFetchRequest<Contact> {
            do {
                // Collect keys in ephemeral keyring
                let keyring = Keyring()
                let contacts = try Contact.moc.fetch(fetchRequest)
                for contact in contacts {
                    if let primaryKey = contact.primaryKey {
                        keyring.import(keys: [primaryKey])
                    }
                }

                // Export keyring to file
                let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("keychain")
                        .appendingPathExtension("gpg")
                try keyring.export().write(to: url, options: .completeFileProtection)
                return .success(url)
            } catch {
                Log.e(error)
                return .failure(error)
            }
        } else {
            let error = ContactExportError.fetchRequestFailed
            Log.e(error.localizedDescription)
            return .failure(error)
        }
    }
}
