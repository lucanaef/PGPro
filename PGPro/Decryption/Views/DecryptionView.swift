//
//  DecryptionView.swift
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

struct DecryptionView: View {
    @StateObject private var viewModel = DecryptionViewModel()

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(title: "Message")

                if let ciphertext = viewModel.ciphertext {
                    ScrollView {
                        Text(ciphertext)
                            .font(.caption.monospaced())
                    }
                } else {
                    VStack(alignment: .center) {
                        Spacer()
                        HStack(alignment: .center) {
                            Spacer()
                            PasteButton(payloadType: String.self) { strings in
                                if let clipboard = strings.first {
                                    DispatchQueue.main.async {
                                        viewModel.ciphertext = clipboard
                                    }
                                }
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                HeaderView(title: "Private Decryption Key")

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(viewModel.decryptionKey)) { contact in
                            NavigationLink {
                                KeyPickerView(withTitle: "Select Decryption Key", type: .privateKey, selection: $viewModel.decryptionKey)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerSize: CGSize(width: 8.0, height: 8.0))
                                        .fill(Color.accentColor)
                                        .frame(maxHeight: 40.0)

                                    VStack(alignment: .leading) {
                                        Text(verbatim: contact.name)
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.white)
                                        Text(verbatim: contact.email)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        if viewModel.decryptionKey.isEmpty {
                            NavigationLink {
                                KeyPickerView(withTitle: "Select Decryption Key", type: .privateKey, selection: $viewModel.decryptionKey)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerSize: CGSize(width: 8.0, height: 8.0))
                                        .strokeBorder(Color.accentColor, lineWidth: 2)
                                        .frame(width: 40.0, height: 40.0, alignment: .center)

                                    Image(systemName: "plus")
                                        .font(.system(.body, design: .rounded, weight: .bold))
                                        .foregroundColor(Color.accentColor)
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            Divider()

            Button(action: {
                #warning("TODO: Implement.")
            }, label: {
                Text("Decrypt")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.vertical)
            .disabled(!viewModel.readyForDecryptionOrPassphrases)
        }
        .padding()
        .navigationTitle("Decryption")
        .sheet(item: $viewModel.decryptionResult) { result in
            DecryptionResultView(decryptionResult: result)
        }
    }
}

struct DecryptionView_Previews: PreviewProvider {
    private static var ciphertext = """
    -----BEGIN PGP MESSAGE-----
    Version: ObjectivePGP
    Comment: https://www.objectivepgp.com
    Charset: UTF-8

    wcFMA7O6h8EEUPukAQ//dWFv6mSXjwZkwaS6bCRmWMwSW4DVoxbeKzmFvXGT00Npt9VuhUZpwxbM
    wsgn8mbDLxYyDc440Z0Z87h6+PuWTzgl1iDALMNoA2RK85no3g5j5H4Y5/RUaJ+25STYviAfh9dT
    0OOzfvxlJatzO945cU4+wOjrHG/rt3JdGsEi6tYCLIBnep2JwpdFr1tjhypOHUjOWK5yWBEDowCe
    15xHxAbJ0zXYEAtTwWvt4ibVQByls1sVPzwZ2n8v6DBrD/Y2CD5WYlddAaW9lN1V1aRGZygvd1qI
    emI4N1Cdlgdr2kYSOSo3HnrWxtwmzeVxXkXVOkNlKALKMhGckU9rR/EwKdLjX3f0nDbjwJ65aZ29
    Y+iaW1ADk78j7ahJRhGPrkkEGRdJF1HMinmw2f7c/SAnAH4a5fuHK/GT/t8anctABnO5wq+9hfEg
    f2S/7VXZbPI2lmh4DMzD4i3W9f1npiqASqdRjZAl5DMqdqnpnXZ19iVPQTUXjTZapcwsPoMTQkLO
    JpFP3JiuLnedFeARLzLNUWxnfD6qusYMNAv2Z8VcSYVz3sEgiQEHXc+/DgDHKVewd+j6JC21N7iJ
    9aQpxRrxu7yXdaxJemwX5RL7s577SxDfK+X50xYLXRLuFa+YVzpqM0+v8hZLcAjEZPIfPXO5XKyb
    eSCMQV8ecv7/oRqRwDzSSQHIA2GzZtpSZTeBk/1jTMkSFF64Rj6rn7e/M4sju3oR80JtVmF9e4cH
    bPbsOah6vz3rg6HC7ga5H+Nt9RQ0ZvIjeW4oEO9+mGo=
    =NLAu
    -----END PGP MESSAGE-----
    """

    static var previews: some View {
        DecryptionView()
    }
}
