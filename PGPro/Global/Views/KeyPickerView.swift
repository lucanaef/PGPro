//
//  KeyPickerView.swift
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

struct KeyPickerView: View {
    var withTitle: String
    var type: KeyPickerType

    enum KeyPickerType {
        case publicKeys
        case privateKeys
        case privateKey
    }

    @Binding var selection: Set<Contact>

    @FetchRequest(sortDescriptors: []) var fetchedContacts: FetchedResults<Contact>
    var selectableContacts: [Contact] {
        switch type {
        case .publicKeys:
            return fetchedContacts.filter({ $0.isPublicKey }).sorted(by: { $0.name <= $1.name })

        case .privateKey, .privateKeys:
            return fetchedContacts.filter({ $0.isPrivateKey }).sorted(by: { $0.name <= $1.name })
        }
    }

    func toggleSelection(for contact: Contact) {
        if selection.contains(contact) {
            selection.remove(contact)
        } else {
            if type == .privateKey {
                selection.removeAll()
            }
            selection.insert(contact)
        }
    }

    var body: some View {
        VStack {
            List {
                ForEach(selectableContacts) { contact in
                    KeychainCardView(contact: contact, selected: selection.contains(contact))
                        .padding(2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            TapticEngine.impact.feedback(.light)
                            toggleSelection(for: contact)
                        }
                }
            }
        }
        .navigationTitle(withTitle)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct KeyPickerView_Previews: PreviewProvider {
    @State static var selection: Set<Contact> = []

    static var previews: some View {
        KeyPickerView(withTitle: "Select Keys", type: .publicKeys, selection: $selection)
    }
}
