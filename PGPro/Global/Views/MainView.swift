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
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject private var routerPath: RouterPath

    @State var userIsNotAuthenticated: Bool = UserDefaults.standard.bool(forKey: UserDefaultsKeys.authenticationEnabled)

    var body: some View {
        TabView(selection: $routerPath.selectedTab) {
            EncryptionView()
                .tabItem {
                    Label("Encryption", systemImage: "lock.fill")
                }
                .tag(RouterPath.Tab.encryption)

            DecryptionView()
                .tabItem {
                    Label("Decryption", systemImage: "lock.open.fill")
                }
                .tag(RouterPath.Tab.decryption)

            KeychainView()
                .tabItem {
                    Label("Keychain", systemImage: "person.2.fill")
                }
                .tag(RouterPath.Tab.keychain)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(RouterPath.Tab.settings)
        }
        .fullScreenCover(isPresented: $userIsNotAuthenticated) {
            LaunchAuthenticationView(userIsNotAuthenticated: $userIsNotAuthenticated)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Log.i("App became active")
            } else if newPhase == .inactive {
                /**
                 Inactive scenes are running and might be visible to the user, but the user isn’t able to access them.
                 For example, if you’re swiping down to partially reveal the control center then the app underneath is considered inactive.
                 */
                Log.i("App became inactive")
            } else if newPhase == .background {
                /**
                 Background scenes are not visible to the user, which on iOS means they might be terminated at some point in the future.
                 */
                Log.i("App moved to background")
                if UserDefaults.standard.bool(forKey: UserDefaultsKeys.authenticationEnabled) {
                    userIsNotAuthenticated = true
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
