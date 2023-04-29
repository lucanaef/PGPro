//
//  MailIntegration.swift
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

enum MailIntegrationError: Error {
    case cannotComposeWhileDisabled
    case noSelectedClient
}

class MailIntegration {
    private init() {}

    typealias MailIntegrationClient = ThirdPartyMailClient

    static var clients: [MailIntegrationClient] {
        var mailClients = [ThirdPartyMailClient.systemDefault] + ThirdPartyMailClient.clients

        // Remove discontinued mail clients
        mailClients.removeAll { ["Sparrow", "Dispatch"].contains($0.name) }

        /*
         Overly complicated sort hierarchy:
            - First is always 'System Default' (mailto:)
            - Next, all the installed clients in lexicographical order
            - Last all the remaining clients in lexicographical order
        */
        mailClients.sort { lhs, rhs in
            if lhs == .systemDefault {
                return true
            } else if rhs == .systemDefault {
                return false
            } else if MailIntegration.isAvailable(lhs) && !MailIntegration.isAvailable(rhs) {
                return true
            } else if !MailIntegration.isAvailable(lhs) && MailIntegration.isAvailable(rhs) {
                return false
            } else {
                return lhs.name < rhs.name
            }
        }

        return mailClients
    }

    private static func client(for name: String) -> MailIntegrationClient? {
        clients.first(where: { $0.name == name })
    }

    static func validateCurrentConfig() {
        if let currentClientName = UserDefaults.standard.string(forKey: UserDefaultsKeys.mailIntegrationClient) {
            if let currentClient = MailIntegration.client(for: currentClientName) {
                // Reset mail client choice if client is not available anymore
                if !ThirdPartyMailer.isMailClientAvailable(currentClient) {
                    // Pre-select system default if available and none other selected
                    if ThirdPartyMailer.isMailClientAvailable(.systemDefault) {
                        UserDefaults.standard.set("System Default", forKey: UserDefaultsKeys.mailIntegrationClient)
                    } else {
                        UserDefaults.standard.set("", forKey: UserDefaultsKeys.mailIntegrationClient)
                        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.mailIntegrationEnabled)
                    }
                }
            }
        }
    }

    static func isAvailable(_ client: MailIntegrationClient) -> Bool {
        return ThirdPartyMailer.isMailClientAvailable(client)
    }

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.mailIntegrationEnabled)
    }

    static func compose(recipients: [String], subject: String? = nil, body: String, completionHandler completion: ((Bool) -> Void)? = nil) throws {
        guard self.isEnabled else {
            throw MailIntegrationError.cannotComposeWhileDisabled
        }

        if let clientName = UserDefaults.standard.string(forKey: UserDefaultsKeys.mailIntegrationClient) {
            if let client = MailIntegration.client(for: clientName) {
                ThirdPartyMailer.openCompose(client, recipient: recipients.joined(separator: ","), subject: subject, body: body, completionHandler: completion)
            } else {
                throw MailIntegrationError.noSelectedClient
            }
        } else {
            throw MailIntegrationError.noSelectedClient
        }
    }
}

extension ThirdPartyMailClient: Equatable {
    public static func == (lhs: ThirdPartyMailClient, rhs: ThirdPartyMailClient) -> Bool {
        return lhs.name == rhs.name
    }
}
