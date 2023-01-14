//
//  LaunchAuthenticationView.swift
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

import SPAlert
import SwiftUI

struct LaunchAuthenticationView: View {
    @Binding var userIsNotAuthenticated: Bool

    @State var presentingAlert: Bool = false
    @State var errorMessage: String = "An unknown error occured!"

    var body: some View {
        VStack {
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .padding()

            Button {
                authenticate()
            } label: {
                Label("Authenticate", systemImage: AuthenticationPreferenceViewModel.symbolName)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accentColor(Color(UIColor.label))
            .foregroundColor(Color(UIColor.systemBackground))
        }
        .onAppear {
            authenticate()
        }
        .SPAlert(isPresent: $presentingAlert,
                 title: "Authentication failed!",
                 message: errorMessage,
                 dismissOnTap: true,
                 preset: .error,
                 haptic: .error
        )
    }

    private func authenticate() {
        Authentication.requestAuthentication { result in
            switch result {
            case .success:
                userIsNotAuthenticated = false

            case .failure(let error):
                errorMessage = error.localizedDescription
                presentingAlert = true
            }
        }
    }
}

struct LaunchAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchAuthenticationView(userIsNotAuthenticated: .constant(false))
    }
}
