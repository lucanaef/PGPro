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

import SPAlert
import SwiftUI
import UniformTypeIdentifiers

struct DecryptionView: View {
    @EnvironmentObject private var routerPath: RouterPath

    @StateObject private var viewModel = DecryptionViewModel()

    @State private var presentingFileImporter: Bool = false
    @State private var presentingPassphraseInput: Bool = false

    @State private var isTargetedForDrop: Bool = false

    @State private var presentingError: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack(path: $routerPath.decryptionTab) {
            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    HeaderView(title: "Message")

                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(isTargetedForDrop ? Color.accentColor.opacity(0.5) : Color(UIColor.systemBackground))

                        Group {
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
                                ZStack {
                                    VStack(alignment: .center) {
                                        Spacer()

                                        Button {
                                            if let clipboard = UIPasteboard.general.string {
                                                DispatchQueue.main.async {
                                                    viewModel.ciphertext = clipboard
                                                }
                                            }
                                        } label: {
                                            Text("Paste from Clipboard")
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 20.0)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.large)

                                        Button {
                                            presentingFileImporter = true
                                        } label: {
                                            VStack {
                                                Image(systemName: "folder")
                                                    .padding(.vertical, 1)
                                                Text("Open from File")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 30.0)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.large)
                                        .accentColor(Color.secondary)

                                        Label("You can also use drag-and-drop or the share sheet to open an encrypted message.", systemImage: "info.circle")
                                            .font(.footnote)
                                            .foregroundColor(Color.secondary)

                                        Spacer()
                                    }
                                    .padding()
                                }
                            }
                        }
                        .opacity(isTargetedForDrop ? 0.2 : 1.0)
                    }
                }
                .SPAlert(isPresent: $presentingError,
                         title: "Decryption failed!",
                         message: errorMessage,
                         duration: 2.0,
                         dismissOnTap: true,
                         preset: .error,
                         haptic: .error)
                .onOpenURL { url in
                    performOnOpenURL(url: url)
                }
                .onDrop(of: [UTType.asc], isTargeted: $isTargetedForDrop, perform: performOnDrop)
                .fileImporter(isPresented: $presentingFileImporter, allowedContentTypes: [UTType.asc], allowsMultipleSelection: false, onCompletion: performOnFileImport)

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

                            NavigationLink(value: RouterPath.DecryptionTabPath.keyPicker) {
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
                        let result = viewModel.decrypt()
                        switch result {
                            case .failure(let error):
                                Log.e(error)
                                errorMessage = error.description
                                presentingError = true

                            case .success(let decryptionResult):
                                routerPath.decryptionTab.append(.result(result: decryptionResult))
                        }
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
                        let result = viewModel.decrypt()
                        switch result {
                            case .failure(let error):
                                Log.e(error)
                                errorMessage = error.description
                                presentingError = true

                            case .success(let decryptionResult):
                                routerPath.decryptionTab.append(.result(result: decryptionResult))
                        }
                    })
                    .interactiveDismissDisabled(true)
                }
            }
            .padding()
            .navigationTitle("Decryption")
            .navigationDestination(for: RouterPath.DecryptionTabPath.self, destination: { destination in
                switch destination {
                    case .keyPicker:
                        KeyPickerView(withTitle: "Select Decryption Key", type: .privateKey, selection: $viewModel.decryptionKey)

                    case .result(result: let plaintext):
                        DecryptionResultView(decryptionResult: plaintext)
                }
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewModel.clear()
                    }
                    .opacity(viewModel.isClear ? 0 : 1)
                }
            }
        }
    }

    // MARK: - Private Helper Functions

    private func performOnFileImport(result: Result<[URL], Error>) {
        switch result {
            case .success(let urls):
                if let fileURL = urls.first {
                    if fileURL.startAccessingSecurityScopedResource() {
                        do {
                            let fileContent = try String(contentsOf: fileURL, encoding: .ascii)
                            viewModel.ciphertext = fileContent
                        } catch {
                            Log.e(error)
                            errorMessage = error.localizedDescription
                            presentingError = true
                        }
                    }

                    fileURL.stopAccessingSecurityScopedResource()
                } else {
                    let error = "Failed to get file URL from file importer"
                    Log.e(error)
                    errorMessage = error
                    presentingError = true
                }

            case .failure(let error):
                Log.e(error)
                errorMessage = error.localizedDescription
                presentingError = true
        }
    }

    private func performOnOpenURL(url: URL) {
        guard url.pathExtension.lowercased() == "asc" else {
            let error = "Only `.asc` files can be opened."
            Log.e(error)
            errorMessage = error
            presentingError = true
            return
        }

        if let fileContent = try? String(contentsOf: url, encoding: .ascii) {
            #warning("TODO: Handle case where file contains a key")
            guard fileContent.isOpenPGPCiphertext else {
                let error = "File is not an OpenPGP message."
                Log.e(error)
                errorMessage = error
                presentingError = true
                return
            }

            routerPath.selectedTab = .decryption
            viewModel.ciphertext = fileContent
        }
    }

    private func performOnDrop(providers: [NSItemProvider]) -> Bool {
        if let provider = providers.first {
            _ = provider.loadDataRepresentation(for: UTType.asc) { (data, error) in
                if let data {
                    let ciphertext = String(bytes: data, encoding: .ascii)
                    Task { @MainActor in
                        viewModel.ciphertext = ciphertext
                    }
                } else if let error {
                    Log.e(error)
                    Task { @MainActor in
                        errorMessage = error.localizedDescription
                        presentingError = true
                    }
                } else {
                    let error = "Failed to load data."
                    Log.e(error)
                    Task { @MainActor in
                        errorMessage = error
                        presentingError = true
                    }
                }
            }

            return true
        } else {
            let error = "Drag-and-Drop failed!"
            Log.e(error)
            errorMessage = error
            presentingError = true
            return false
        }
    }
}

struct DecryptionView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptionView()
    }
}
