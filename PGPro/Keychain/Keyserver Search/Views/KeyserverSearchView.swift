//
//  KeyserverSearchView.swift
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
import SPAlert
import SwiftUI

struct KeyserverSearchView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var viewModel = KeyserverSearchViewModel()
    @State private var searchText = ""

    @State private var presentingCodeScannerView: Bool = false

    @State private var importSuccessful: Bool = false
    @State private var importFailed: Bool = false

    @State private var presentingErrorDialog: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    List {
                        ForEach(viewModel.results) { result in
                            KeyserverSearchResultCardView(result: result)
                                .onTapGesture {
                                    let success = Contact.add(from: result.key)
                                    importSuccessful = success
                                    importFailed = !success
                                }
                                .SPAlert(isPresent: $importFailed,
                                         message: "Import Failed!",
                                         duration: 1.0,
                                         dismissOnTap: true,
                                         preset: .error,
                                         haptic: .error
                                )
                                .SPAlert(isPresent: $importSuccessful,
                                         message: "Success!",
                                         duration: 1.0,
                                         dismissOnTap: true,
                                         preset: .done,
                                         haptic: .success) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search by Email, Fingerprint or Key ID", suggestions: {
                        Button {
                            presentingCodeScannerView = true
                        } label: {
                            Label("Scan QR Code", systemImage: "qrcode")
                        }
                    })
                    .onSubmit(of: .search) {
                        Task {
                            await viewModel.search(for: searchText)
                        }
                    }

                    if viewModel.isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .sheet(isPresented: $presentingCodeScannerView) {
                    CodeScannerView(codeTypes: [.qr]) { scanResult in
                        switch scanResult {
                            case .failure(let error):
                                Log.e(error)
                                presentingCodeScannerView = false
                                errorMessage = error.localizedDescription
                                presentingErrorDialog = true
                                return

                            case .success(let code):
                                guard code.contains("OPENPGP4FPR:") else {
                                    Log.e("Invalid QR Code.")
                                    presentingCodeScannerView = false
                                    errorMessage = "Invalid QR Code"
                                    presentingErrorDialog = true
                                    return
                                }

                                let parsedCode = code.replacingOccurrences(of: "OPENPGP4FPR:", with: "")
                                searchText = parsedCode
                                presentingCodeScannerView = false
                        }
                    }
                }
                .SPAlert(isPresent: $presentingErrorDialog,
                         title: "Failed to scan QR code!",
                         message: errorMessage,
                         dismissOnTap: true,
                         preset: .error,
                         haptic: .error
                )
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Search Keyserver")
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
            }
        }
    }
}

struct KeyserverSearchView_Previews: PreviewProvider {
    static var previews: some View {
        KeyserverSearchView()
    }
}
