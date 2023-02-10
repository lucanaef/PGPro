//
//  LicencesView.swift
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

struct LicencesView: View {
    @Environment(\.openURL) var openURL

    var body: some View {
        List(Licenses.allLicenses, id: \.title) { license in
            Button {
                openURL(license.licenseURL)
            } label: {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            Text(license.title)
                                .foregroundColor(.primary)
                                .fontWeight(0.0)

                            if let type = license.licenseType {
                                Text(type.description)
                                    .padding(.vertical, 2.0)
                                    .padding(.horizontal, 8.0)
                                    .font(.caption2)
                                    .monospaced()
                                    .foregroundColor(.white)
                                    .background(type.color)
                                    .cornerRadius(25)
                            }
                        }
                        
                        Text(license.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(2)

                    Spacer()

                    Image(systemName: "chevron.forward")
                }
            }
        }
        .navigationTitle("Licences")
    }
}

struct LicencesView_Previews: PreviewProvider {
    static var previews: some View {
        LicencesView()
    }
}
