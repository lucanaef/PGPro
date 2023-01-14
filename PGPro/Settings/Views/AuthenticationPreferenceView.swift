//
//  AuthenticationPreferenceView.swift
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

struct AuthenticationPreferenceView: View {
    @AppStorage(UserDefaultsKeys.authenticationEnabled) var authenticationEnabled: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $authenticationEnabled) {
                    Text("App Launch Authentication")
                }
                .disabled(!AuthenticationPreferenceViewModel.isAvailable)
            } footer: {
                Text("If enabled, authentication will be required when launching PGPro.")
            }

            if !AuthenticationPreferenceViewModel.isAvailable {
                Section {
                    Label("Biometric authentication is not available on this device.", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.gray)
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.gray.opacity(0.2))
            }
        }
        .navigationTitle("Authentication")
    }
}

struct AuthenticationPreferenceView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationPreferenceView()
    }
}
