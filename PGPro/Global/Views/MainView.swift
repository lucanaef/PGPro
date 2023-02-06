//
//  MainView.swift
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

struct MainView: View {
    /**
     `userIsNotAuthenticated` is initially true <-> App Launch Authentication is required
     Whether this is hacky or elegant is up to you to decice.
     */
    @State var userIsNotAuthenticated: Bool = UserDefaults.standard.bool(forKey: UserDefaultsKeys.authenticationEnabled)

    var body: some View {
        TabView {
            EncryptionView()
                .tabItem {
                    Label("Encryption", systemImage: "lock.fill")
                }
            DecryptionInputView()
                .tabItem {
                    Label("Decryption", systemImage: "lock.open.fill")
                }
            KeychainView()
                .tabItem {
                    Label("Keychain", systemImage: "person.2.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .fullScreenCover(isPresented: $userIsNotAuthenticated) {
            LaunchAuthenticationView(userIsNotAuthenticated: $userIsNotAuthenticated)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
