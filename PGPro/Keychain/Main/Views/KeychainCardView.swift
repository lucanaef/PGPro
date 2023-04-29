//
//  KeychainCardView.swift
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

struct KeychainCardView: View {
    private var viewModel: KeychainCardViewModel

    init(contact: Contact, selected: Bool = false) {
        viewModel = KeychainCardViewModel(contact: contact, selected: selected)
    }

    private var attributes: [(String, String)] {
        return [("Key ID", viewModel.keyID), ("Expiration", viewModel.expirationDate), ("Fingerprint", viewModel.fingerprint)]
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                UserAvatarView(name: viewModel.name, selected: viewModel.selected)

                VStack(alignment: .leading) {
                    Text(viewModel.name)
                        .bold()
                    Text(viewModel.email)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.systemGray))
                }
            }

            ScrollView(.horizontal) {
                HStack(alignment: .top) {
                    ForEach(attributes, id: \.0) { attribute in
                        VStack(alignment: .leading) {
                            Text(attribute.0)
                                .foregroundColor(Color(UIColor.systemGray))
                                .font(.caption)
                                .bold()

                            Text(attribute.1)
                                .foregroundColor(Color(UIColor.systemGray))
                                .font(.caption)
                                .monospaced()
                        }
                        .padding(.trailing)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct KeychainCard_Previews: PreviewProvider {
    static var previews: some View {
        KeychainView()
    }
}
