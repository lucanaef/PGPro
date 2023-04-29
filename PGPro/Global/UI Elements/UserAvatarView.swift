//
//  UserAvatarView.swift
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

struct UserAvatarView: View {
    var name: String
    var selected = false

    private let size = 40.0

    var body: some View {
        if selected {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: size, height: size, alignment: .center)

                Image(systemName: "checkmark")
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size, alignment: .center)
        } else {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: size, height: size, alignment: .center)

                InitialsView(name: name)
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size, alignment: .center)
        }
    }
}

struct UserAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            UserAvatarView(name: "Luca Näf")
        }
        .fixedSize(horizontal: true, vertical: true)
    }
}
