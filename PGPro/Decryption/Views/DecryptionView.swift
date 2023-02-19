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

    @State private var presentingPassphraseInput: Bool = false

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(title: "Message")

                if let ciphertext = viewModel.ciphertext {
                    ZStack {
                        ScrollView {
                            Text(ciphertext)
                                .font(.caption.monospaced())
                        }

                        if !ciphertext.isOpenPGPCiphertext {
                            HStack {
                                Spacer()

                                Label("Invalid OpenPGP Message", systemImage: "exclamationmark.triangle.fill")
                                    .padding()
                                    .foregroundColor(.primary)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(15)

                                Spacer()
                            }
                        }
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
                .scrollIndicators(.hidden)
            }

            Divider()

            Button(action: {
                // Ask for passphrases if required
                presentingPassphraseInput = viewModel.passphraseInputRequired

                // Check if all required passphrases are known
                if !viewModel.somePassphrasesRequired {
                    viewModel.decrypt()
                }
            }, label: {
                Text("Decrypt")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.vertical)
            .disabled(!viewModel.readyForDecryptionOrPassphrases)
            .sheet(isPresented: $presentingPassphraseInput) {
                PassphraseInputView(contacts: viewModel.decryptionKey.filter({ $0.requiresPassphrase }), passphraseForKey: $viewModel.passphraseForKey, onDismiss: {
                    viewModel.decrypt()
                })
                .interactiveDismissDisabled(true)
            }
        }
        .padding()
        .navigationTitle("Decryption")
        .sheet(item: $viewModel.decryptionResult) { result in
            DecryptionResultView(decryptionResult: result)
        }
    }
}

struct DecryptionView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptionView()
    }
}
