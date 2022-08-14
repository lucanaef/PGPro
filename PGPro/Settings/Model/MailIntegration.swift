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

    static var clients: [ThirdPartyMailClient] = {
        var mailClients = [ThirdPartyMailClient.systemDefault] + ThirdPartyMailClient.clients
        mailClients.removeAll { ["Sparrow", "Dispatch"].contains($0.name) } // remove discontinued mail clients
        return mailClients
    }()

    static var selectedClient: ThirdPartyMailClient? {
        get {
            if let clientName = Preferences.mailIntegrationClientName {
                return clients.first(where: { $0.name == clientName })
            } else {
                return nil
            }
        }
        set {
            Preferences.mailIntegrationClientName = newValue?.name
        }
    }

    static var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: Preferences.UserDefaultsKeys.mailIntegration)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Preferences.UserDefaultsKeys.mailIntegration)
            // Reset mail client choice if client is not available anymore
            if let previouslySelectedClient = selectedClient, !ThirdPartyMailer.isMailClientAvailable(previouslySelectedClient) {
                selectedClient = nil
            }
            // Pre-select system default if available and none other selected
            if selectedClient == nil, ThirdPartyMailer.isMailClientAvailable(.systemDefault) {
                selectedClient = .systemDefault
            }
        }
    }

    static func isAvailable(_ client: MailIntegrationClient) -> Bool {
        return ThirdPartyMailer.isMailClientAvailable(client)
    }

    static func compose(recipients: [String], subject: String? = nil, body: String, completionHandler completion: ((Bool) -> Void)? = nil) throws {
        guard self.isEnabled else { throw MailIntegrationError.cannotComposeWhileDisabled }
        if let client = self.selectedClient {
            ThirdPartyMailer.openCompose(client, recipient: recipients.joined(separator: ","), subject: subject, body: body, completionHandler: completion)
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
