//
//  KeyDetailView.swift
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

struct KeyDetailView: View {
    @ObservedObject var viewModel: KeyDetailViewModel

    @Environment(\.managedObjectContext) var moc

    @State private var presentingDeletionConfirmationDialog = false

    private func delete(contact: Contact) {
        moc.delete(contact)
        try? moc.save()
    }

    var body: some View {
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
                        TextField("Name", text: $viewModel.contact.name)
                            .bold()

                        Divider()

                        TextField("Email Address", text: .constant(viewModel.email))
                            .disabled(true)
                    }
                }
            } header: {
                Text("User Info")
            }

            Section {
                VStack(alignment: .leading) {
                    Text("Type")
                        .bold()
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.keyType)
                        .font(.subheadline)
                        .monospaced()
                }

                VStack(alignment: .leading) {
                    Text("Identifer")
                        .bold()
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.keyID)
                        .font(.subheadline)
                        .monospaced()
                }

                VStack(alignment: .leading) {
                    Text("Expiration Date")
                        .bold()
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.expirationDate)
                        .font(.subheadline)
                        .monospaced()
                }

                VStack(alignment: .leading) {
                    Text("Fingerprint")
                        .bold()
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(viewModel.fingerprint)
                        .monospaced()
                        .font(.subheadline)
                }
            } header: {
                Text("Primary Key")
            }

            Section {
                if viewModel.contact.primaryKey?.isPublic ?? false, let keyString = viewModel.exportablePublicKey {
                    ShareLink(item: keyString) {
                        Label("Share Public Key", systemImage: "square.and.arrow.up")
                            .foregroundColor(.accentColor)
                    }
                }

                if viewModel.contact.primaryKey?.isSecret ?? false, let keyString = viewModel.exportablePrivateKey {
                    ShareLink(item: keyString) {
                        Label("Export Private Key", systemImage: "square.and.arrow.up")
                            .foregroundColor(.red)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    presentingDeletionConfirmationDialog = true
                } label: {
                    Label("Delete Key", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .alert("Are you sure?", isPresented: $presentingDeletionConfirmationDialog) {
                    Button("Cancel", role: .cancel) {
                        ()
                    }

                    Button("Delete", role: .destructive) {
                        delete(contact: viewModel.contact)
                    }
                } message: {
                    Text("This action cannot be undone.")
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(viewModel.keyID == "-" ? "Contact" : viewModel.keyID)
    }
}

struct KeyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        KeyDetailView(viewModel: KeyDetailViewModel(MockData.contacts.first!))
    }
}
