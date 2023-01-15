//
//  MailIntegrationPreferenceView.swift
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

import SwiftUI

struct MailIntegrationPreferenceView: View {
    @AppStorage(UserDefaultsKeys.mailIntegrationEnabled) var mailIntegrationEnabled: Bool = false
    @AppStorage(UserDefaultsKeys.mailIntegrationClient) var mailIntegrationClientName: String = ""

    private let infoText = "If enabled, PGPro will open the selected mail client after encrypting a message."

    var body: some View {
        List {
            Section {
                Toggle(isOn: $mailIntegrationEnabled) {
                    Text("Mail Integration")
                }
            } footer: {
                if !mailIntegrationEnabled {
                    Text(infoText)
                }
            }

            if mailIntegrationEnabled {
                Section {
                    ForEach(MailIntegration.clients, id: \.name) { client in
                        HStack {
                            if client == .systemDefault {
                                VStack(alignment: .leading) {
                                    Text(client.name)
                                    Text("Default Mail Client")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Image(client.name)
                                    .resizable()
                                    .frame(width: 30.0, height: 30.0)
                                    .shadow(radius: 0.5)
                                    .grayscale(MailIntegration.isAvailable(client) ? 0.0 : 1.0)
                                VStack(alignment: .leading) {
                                    Text(client.name)
                                        .foregroundColor(MailIntegration.isAvailable(client) ? Color(UIColor.label) : .gray)
                                    if !MailIntegration.isAvailable(client) {
                                        Text("Not installed")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            Spacer()

                            if mailIntegrationClientName == client.name {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if MailIntegration.isAvailable(client) {
                                mailIntegrationClientName = client.name
                            }
                        }
                    }
                } header: {
                    Text("Mail Client")
                } footer: {
                    Text(infoText)
                }
            }
        }
        .navigationTitle("Mail Integration")
        .onAppear {
            MailIntegration.validateCurrentConfig()
        }
    }
}

struct MailIntegrationPreferenceView_Previews: PreviewProvider {
    static var previews: some View {
        MailIntegrationPreferenceView()
    }
}
