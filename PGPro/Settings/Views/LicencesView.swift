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
                VStack(alignment: .leading) {
                    Text(license.title)
                        .foregroundColor(.primary)
                    Text(license.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(2)
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
