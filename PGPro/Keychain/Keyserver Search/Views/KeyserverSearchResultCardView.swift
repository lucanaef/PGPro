//
//  KeyserverSearchResultCardView.swift
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

struct KeyserverSearchResultCardView: View {
    var result: KeyserverSearchResult

    private var keyID: String {
        result.key.publicKey?.keyID.shortIdentifier.insertSeparator(" ", atEvery: 4) ?? "-"
    }

    private var fingerprint: String {
        result.key.publicKey?.fingerprint.description().insertSeparator(" ", atEvery: 4) ?? "-"
    }

    private var expirationDate: String {
        if let date = result.key.expirationDate {
            return ISO8601DateFormatter.string(from: date, timeZone: .autoupdatingCurrent, formatOptions: .withFullDate)
        } else {
            return "Never"
        }
    }

    private var attributes: [(String, String)] {
        return [("Key ID", keyID), ("Expiration", expirationDate), ("Fingerprint", fingerprint)]
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                UserAvatarView(name: result.key.publicKey?.primaryUser?.userID ?? "", selected: false)

                VStack(alignment: .leading) {
                    Text(result.key.publicKey?.primaryUser?.userID ?? "Unknown Contact")
                        .bold()
                    Text("From " + result.origin.description)
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
