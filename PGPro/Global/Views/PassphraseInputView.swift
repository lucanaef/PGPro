//
//  PassphraseInputView.swift
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

import ObjectivePGP
import SwiftUI

struct PassphraseInputView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage(UserDefaultsKeys.accentColor) var accentColor: String = Color.accentColor.rawValue

    var contacts: [Contact]
    @Binding var passphraseForKey: [Key: String]

    var onDismiss: (() -> Void)?

    private var allPassphrasesCorrectlyEntered: Bool {
        contacts.filter({ $0.requiresPassphrase }).allSatisfy { contact in
            if let key = contact.primaryKey, let passphrase = passphraseForKey[key] {
                return OpenPGP.verifyPassphrase(passphrase, for: key)
            } else {
                return false
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                ForEach(contacts) { contact in
                    SinglePassphraseInputView(contact: contact, passphraseForKey: $passphraseForKey) {
                        if allPassphrasesCorrectlyEntered {
                            dismiss()
                            onDismiss?()
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Passphrase")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .accentColor(Color(rawValue: accentColor))
        }
    }

    struct SinglePassphraseInputView: View {
        var contact: Contact

        @Binding var passphraseForKey: [Key: String]

        var onComplete: (() -> Void)?

        @State private var passphrase: String = ""
        @State private var passphraseIsCorrect: Bool?

        private func checkPassphrase() {
            if passphrase.isEmpty {
                passphraseIsCorrect = nil
            } else if let key = contact.primaryKey {
                passphraseIsCorrect = OpenPGP.verifyPassphrase(passphrase, for: key)
                if passphraseIsCorrect ?? false { onComplete?() }
            } else {
                Log.e("Failed to unwrap primary key for contact \(contact.id)")
                passphraseIsCorrect = nil
            }
        }

        var body: some View {
            Section {
                KeychainCardView(contact: contact)
                SecureField("Passphrase", text: $passphrase)
                    .textContentType(.password)
                    .onSubmit {
                        if let key = contact.primaryKey {
                            passphraseForKey[key] = passphrase
                            checkPassphrase()
                        } else {
                            Log.e("Failed to unwrap primary key for contact \(contact.id)")
                        }
                    }
            } footer: {
                switch passphraseIsCorrect {
                    case .none:
                        EmptyView()

                    case .some(let isCorrect):
                        switch isCorrect {
                            case true:
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Passphrase correct")
                                }
                                .foregroundColor(.green)

                            case false:
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Passphrase incorrect")
                                }
                                .foregroundColor(.red)
                            }
                }
            }
        }
    }
}
