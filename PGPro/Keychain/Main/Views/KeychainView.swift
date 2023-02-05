//
//  KeychainView.swift
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

struct KeychainView: View {
    @FetchRequest(sortDescriptors: []) var fetchedContacts: FetchedResults<Contact>

    @AppStorage(UserDefaultsKeys.accentColor) var selectedAccentColor: String = Color.accentColor.rawValue

    @State private var searchText = ""

    @State private var importSuccessful: Bool = false
    @State private var importFailed: Bool = false
    @State private var importMessage: String?

    @State private var presentingGenerateKeyPair = false
    @State private var presentingKeyserverSearch = false
    @State private var presentingFileImporter = false

    private var contacts: [Contact] {
        var filteredData: [Contact] = []
        let lowercasedSearchText = searchText.lowercased()

        if searchText.isEmpty {
            return fetchedContacts.sorted(by: { $0.name <= $1.name })
        } else {
            filteredData = fetchedContacts.filter { user in
                user.name.lowercased().contains(lowercasedSearchText) || user.email.contains(lowercasedSearchText)
            }
            return filteredData.sorted(by: { $0.name <= $1.name })
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if contacts.isEmpty {
                    KeychainEmptyView()
                } else {
                    List {
                        Section {
                            ForEach(contacts.filter({ $0.isPrivateKey })) { contact in
                                NavigationLink(destination: KeyDetailView(viewModel: KeyDetailViewModel(contact))) {
                                    KeychainCardView(contact: contact)
                                        .padding(2)
                                }
                            }
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        } header: {
                            Text("Private Keys")
                        }

                        Section {
                            ForEach(contacts.filter({ $0.isPublicKey && !$0.isPrivateKey })) { contact in
                                NavigationLink(destination: KeyDetailView(viewModel: KeyDetailViewModel(contact))) {
                                    KeychainCardView(contact: contact)
                                        .padding(2)
                                }
                            }
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        } header: {
                            Text("Public Keys")
                        }
                    }
                }
            }
            .navigationTitle("Keychain")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            presentingGenerateKeyPair = true
                        } label: {
                            Label("Generate Key Pair", systemImage: "gearshape.2")
                        }

                        Button {
                            presentingKeyserverSearch = true
                        } label: {
                            Label("Search on Keyserver", systemImage: "magnifyingglass")
                        }

                        Button {
                            presentingFileImporter = true
                        } label: {
                            Label("Import from File", systemImage: "folder.badge.plus")
                        }

                        PasteButton(payloadType: String.self) { strings in
                            let result = Contact.add(from: strings[0])
                            importMessage = result.description
                            if result.successful > 0 {
                                importSuccessful = true
                            } else {
                                importFailed = true
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .fullScreenCover(isPresented: $presentingGenerateKeyPair) {
                GenerateKeyPairView()
                    .accentColor(Color(rawValue: selectedAccentColor))
            }
            .fullScreenCover(isPresented: $presentingKeyserverSearch) {
                KeyserverSearchView()
                    .accentColor(Color(rawValue: selectedAccentColor))
            }
            .fileImporter(isPresented: $presentingFileImporter, allowedContentTypes: [.data], onCompletion: { result in
                switch result {
                case .success(let fileURL):
                    do {
                        guard fileURL.startAccessingSecurityScopedResource() else {
                            Log.e("fileURL.startAccessingSecurityScopedResource() failed!")
                            presentingFileImporter = false
                            importFailed = true
                            return
                        }
                        let data = try Data(contentsOf: fileURL)
                        let keys = try OpenPGP.keys(from: data)

                        let result = Contact.add(from: keys)
                        importMessage = result.description
                        if result.successful > 0 {
                            importSuccessful = true
                        } else {
                            importFailed = true
                        }
                    } catch {
                        Log.e(error)
                        presentingFileImporter = false
                        importFailed = true
                    }

                case .failure(let error):
                    Log.e(error)
                    importFailed = true
                }
            })
            .SPAlert(isPresent: $importFailed,
                     message: importMessage,
                     duration: 1.0,
                     dismissOnTap: true,
                     preset: .error,
                     haptic: .error
            )
            .SPAlert(isPresent: $importSuccessful,
                     message: importMessage,
                     duration: 1.0,
                     dismissOnTap: true,
                     preset: .done,
                     haptic: .success
            )
        }
    }
}

struct KeychainView_Previews: PreviewProvider {
    static var previews: some View {
        KeychainView()
    }
}
