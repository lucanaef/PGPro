//
//  GenerateKeyPairView.swift
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

struct GenerateKeyPairView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var viewModel = GenerateKeyPairViewModel()

    @FocusState private var focusedField: GenerateKeyPairViewModel.Field?

    @State private var presentingSpinner: Bool = false
    @State private var presentingErrorMessage: Bool = false
    @State private var presentingSuccessMessage: Bool = false
    @State private var errorMessage: String = "Key Generation Failed!"

    private var keyboardActive: Bool {
        focusedField != nil
    }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 40.0, height: 40.0, alignment: .center)

                                InitialsView(name: viewModel.name)
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 4.0)

                            VStack {
                                TextField("Name", text: $viewModel.name)
                                    .keyboardType(.namePhonePad)
                                    .bold(!viewModel.name.isEmpty)
                                    .focused($focusedField, equals: .name)

                                Divider()

                                TextField("Email Address", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                            }
                        }
                    } header: {
                        Text("User Info")
                    }

                    Section {
                        SecureField("Passphrase", text: $viewModel.passphrase)
                            .focused($focusedField, equals: .passphrase)

                        SecureField("Confirm Passphrase", text: $viewModel.passphraseConfirm)
                            .focused($focusedField, equals: .passphraseConfirm)
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading) {
                                    Spacer()

                                    Rectangle()
                                        .foregroundColor(viewModel.passphraseStrengthColor)
                                        .frame(width: viewModel.passphraseStrength*750, height: 10)
                                        .listRowInsets(EdgeInsets())
                                        .position(x: -10, y: 23)
                                }
                            }
                    } header: {
                        Text("Security")
                    } footer: {
                        Label("If you forget your passphrase, there is no way to recover it.", systemImage: "info.circle")
                    }

                    if !viewModel.allFieldsEmpty && focusedField == nil {
                        if case .failure(let error) = viewModel.validateInput() {
                            Section {
                                Label(error.description, systemImage: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                            }
                            .scrollContentBackground(.hidden)
                            .listRowBackground(Color.red.opacity(0.2))
                        }
                    }
                }
                .onSubmit {
                    switch focusedField {
                    case .name:
                        focusedField = .email

                    case .email:
                        focusedField = .passphrase

                    case .passphrase:
                        focusedField = .passphraseConfirm

                    case .passphraseConfirm:
                        focusedField = nil

                    case .none:
                        focusedField = nil
                    }
                }

                Button(action: {
                    presentingSpinner = true
                    let result = viewModel.generateKey()
                    switch result {
                    case .failure(let error):
                        presentingSpinner = false
                        errorMessage = error.localizedDescription
                        presentingErrorMessage = true

                    case .success:
                        presentingSpinner = false
                        presentingSuccessMessage = true
                    }
                }, label: {
                    Text("Generate")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .disabled(!viewModel.generateButtonEnabled)
                .SPAlert(isPresent: $presentingSpinner,
                         title: "Generating Key Pair...",
                         duration: .infinity,
                         dismissOnTap: false,
                         preset: .spinner)
                .SPAlert(isPresent: $presentingErrorMessage,
                         message: errorMessage,
                         duration: 4.0,
                         dismissOnTap: true,
                         preset: .error,
                         haptic: .error
                )
                .SPAlert(isPresent: $presentingSuccessMessage,
                         message: "Success!",
                         duration: 1.0,
                         dismissOnTap: true,
                         preset: .done,
                         haptic: .success
                ) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Generate Key Pair")
            .ignoresSafeArea(.keyboard)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Spacer()

                    Button(role: .cancel) {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button {
                        focusedField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
    }
}

struct GenerateKeyPairView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateKeyPairView()
    }
}
