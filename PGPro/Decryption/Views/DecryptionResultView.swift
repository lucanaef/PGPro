//
//  DecryptionResultView.swift
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

struct DecryptionResultView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage(UserDefaultsKeys.accentColor) var accentColor: String = Color.accentColor.rawValue

    var decryptionResult: OpenPGP.DecryptionResult

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(title: "Message")

                ScrollView {
                    switch decryptionResult.message {
                        case .plain(value: let message):
                            Text(message)

                        case .mime(value: let mime):
                            if let message = try? mime.1.decodedContentString() {
                                Text(message)
                            } else {
                                Label("Failed to decode mime content.", systemImage: "exclamationmark.triangle.fill")
                                    .padding()
                                    .foregroundColor(.primary)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(15)

                                Text(mime.0)
                            }
                    }
                }

                Spacer()
                
                Divider()
                    .padding(.bottom)

                HStack {
                    if let plaintext = decryptionResult.plaintext {
                        ShareLink(item: plaintext) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Decryption")
            .accentColor(Color(rawValue: accentColor))
        }
    }
}

struct DecryptionResultView_Previews: PreviewProvider {
    static var decryptionResultPlain = OpenPGP.DecryptionResult(message: .plain(value: """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut
    labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
    laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit
    in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
    cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque
    laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto
    beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut
    odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.
    Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit,
    sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat
    voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit
    laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit
    qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum
    fugiat quo voluptas nulla pariatur?
    """), signatures: "")

    static var previews: some View {
        DecryptionResultView(decryptionResult: decryptionResultPlain)
    }
}
