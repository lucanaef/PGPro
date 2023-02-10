//
//  EncryptionView.swift
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

struct EncryptionView: View {
    @StateObject private var viewModel = EncryptionViewModel()

    @AppStorage(UserDefaultsKeys.mailIntegrationEnabled) var mailIntegrationEnabled: Bool = false

    @FocusState private var presentingKeyboard: Bool

    @State private var presentingPassphraseInput: Bool = false
    @State private var presentingCopiedToClipboard: Bool = false
    @State private var presentingEncryptionError: Bool = false
    @State private var presentingMailComposeError: Bool = false

    @State private var encryptionErrorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                // Recipients
                VStack(alignment: .leading, spacing: 0) {
                    HeaderView(title: "Recipients")

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(viewModel.recipients)) { contact in
                                UserAvatarView(name: contact.name)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.recipients.remove(contact)
                                        } label: {
                                            Label("Remove Recipient", systemImage: "person.badge.minus")
                                        }
                                    } preview: {
                                        HStack(alignment: .center) {
                                            UserAvatarView(name: contact.name)
                                            VStack(alignment: .leading) {
                                                Text(contact.name)
                                                Text(contact.email)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                    }
                            }

                            NavigationLink {
                                KeyPickerView(withTitle: "Select Recipients", type: .publicKeys, selection: $viewModel.recipients)
                            } label: {
                                ZStack {
                                    Circle()
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

                // Message
                VStack(alignment: .leading, spacing: 0) {
                    HeaderView(title: "Message")

                    PlaceholderTextEditor(placeholder: viewModel.placeholder, text: $viewModel.message)
                        .multilineTextAlignment(.leading)
                        .scrollContentBackground(.hidden)
                        .focused($presentingKeyboard)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()

                                Button(role: .cancel) {
                                    presentingKeyboard = false
                                } label: {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                }
                            }
                        }
                }

                // Signatures
                VStack(alignment: .leading, spacing: 0) {
                    HeaderView(title: "Signatures")

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(Array(viewModel.signers)) { contact in
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
                                .contextMenu {
                                    Button(role: .destructive) {
                                        viewModel.signers.remove(contact)
                                    } label: {
                                        Label("Remove Signature", systemImage: "person.badge.minus")
                                    }
                                } preview: {
                                    HStack(alignment: .center) {
                                        UserAvatarView(name: contact.name)
                                        VStack(alignment: .leading) {
                                            Text(contact.name)
                                            Text(contact.email)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                }
                            }

                            NavigationLink {
                                KeyPickerView(withTitle: "Select Signing Keys", type: .privateKeys, selection: $viewModel.signers)
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
                        encryptMessage()
                    }
                }, label: {
                    Text("Encrypt")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.vertical)
                .disabled(!viewModel.readyForEncryptionOrPassphrases)
                .sheet(isPresented: $presentingPassphraseInput) {
                    PassphraseInputView(contacts: viewModel.signers.filter({ $0.requiresPassphrase }), passphraseForKey: $viewModel.passphraseForKey, onDismiss: {
                        encryptMessage()
                    })
                    .interactiveDismissDisabled(true)
                }
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Encryption")
            .ignoresSafeArea(.keyboard)
            .SPAlert(isPresent: $presentingCopiedToClipboard,
                     title: "Copied to Clipboard!",
                     duration: 2.0,
                     dismissOnTap: true,
                     preset: .done,
                     haptic: .success)
            .SPAlert(isPresent: $presentingEncryptionError,
                     title: "Encryption failed!",
                     message: encryptionErrorMessage,
                     duration: 2.0,
                     dismissOnTap: true,
                     preset: .error,
                     haptic: .error)
            .SPAlert(isPresent: $presentingMailComposeError,
                     title: "Failed to compose email!",
                     duration: 2.0,
                     dismissOnTap: true,
                     preset: .error,
                     haptic: .error)
        }
    }

    private func encryptMessage() {
        do {
            let encryptedMessage = try viewModel.encrypt()

            if mailIntegrationEnabled {
                // Compose email
                do {
                    try MailIntegration.compose(recipients: viewModel.recipients.map({ $0.email }).filter({ $0.isValidEmail }), body: encryptedMessage)
                } catch {
                    // Present error
                    presentingMailComposeError = true
                }
            } else {
                // Copy encrypted message to clipboard
                UIPasteboard.general.string = encryptedMessage
                presentingCopiedToClipboard = true
            }
        } catch {
            // Present error
            encryptionErrorMessage = error.localizedDescription
            presentingEncryptionError = true
        }
    }
}

struct EncryptionView_Previews: PreviewProvider {
    static var previews: some View {
        EncryptionView()
    }
}
