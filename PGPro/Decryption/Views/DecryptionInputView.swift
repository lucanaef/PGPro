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
import UniformTypeIdentifiers

struct DecryptionInputView: View {
    @State private var ciphertext: String?

    @State private var presentingFileImporter: Bool = false
    @State private var presentingDecryptionView: Bool = false

    @State private var presentingError: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                VStack {
                    Spacer()

                    Button {
                        ciphertext = UIPasteboard.general.string
                        presentingDecryptionView = true
                    } label: {
                        Text("Paste from Clipboard")
                            .frame(maxWidth: .infinity)
                            .frame(height: 20.0)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    HStack {
                        Button {
                            presentingFileImporter = true
                        } label: {
                            VStack {
                                Image(systemName: "folder")
                                    .padding(.vertical, 1)
                                Text("Open File")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 30.0)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            #warning("Implement button action.")
                            print("button pressed")
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .padding(.vertical, 1)
                                Text("Share Menu")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 30.0)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .accentColor(Color.secondary)

                    Label("You can also drag-and-drop a file here.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundColor(Color.secondary)

                    Spacer()
                }
                .padding(50)
                .background(Color(UIColor.systemGroupedBackground))
                .navigationDestination(isPresented: $presentingDecryptionView, destination: {
                    DecryptionView {
                        return ciphertext
                    }
                })
                .SPAlert(isPresent: $presentingError,
                         title: "Decryption failed!",
                         message: errorMessage,
                         duration: 2.0,
                         dismissOnTap: true,
                         preset: .error,
                         haptic: .error)
                .onOpenURL { url in
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

                        ciphertext = fileContent
                        presentingDecryptionView = true
                    }
                }
                .onDrop(of: [UTType.asc], isTargeted: nil, perform: { providers in
                    if let provider = providers.first {
                        _ = provider.loadDataRepresentation(for: UTType.asc) { (data, error) in
                            if let data {
                                ciphertext = String(bytes: data, encoding: .ascii)
                                presentingDecryptionView = true
                            } else if let error {
                                Log.e(error)
                                errorMessage = error.localizedDescription
                                presentingError = true
                            } else {
                                let error = "Failed to load data."
                                Log.e(error)
                                errorMessage = error
                                presentingError = true
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
                })
                .fileImporter(isPresented: $presentingFileImporter, allowedContentTypes: [UTType.asc], allowsMultipleSelection: false) { result in
                    switch result {
                        case .success(let urls):
                            if let fileURL = urls.first {
                                if fileURL.startAccessingSecurityScopedResource() {
                                    do {
                                        let fileContants = try String(contentsOf: fileURL, encoding: .ascii)
                                        ciphertext = fileContants
                                        presentingDecryptionView = true
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
            }
            .navigationTitle("Decryption")
        }
    }
}

struct DecryptionInputView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptionInputView()
    }
}
