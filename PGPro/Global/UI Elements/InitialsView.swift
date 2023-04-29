//
//  InitialsView.swift
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

struct InitialsView: View {
    var name: String
    var initials: String? {
        initials(of: name)
    }

    var body: some View {
        if let initials {
            Text(verbatim: initials)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
        } else {
            Image(systemName: "person.fill")
        }
    }

    func initials(of name: String) -> String? {
        let names = name
            .replacingOccurrences(of: "\\s?\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s?\\<[^>]*\\>", with: "", options: .regularExpression)
            .split(separator: " ").map({ String($0) })

        switch names.count {
            case 0:
                return nil

            case 1:
                return names.first!.first?.uppercased()

            default:
                if let firstNamefirstLetter = names.first!.first, let lastNamefirstLetter = names.last!.first {
                    return (String(firstNamefirstLetter) + String(lastNamefirstLetter)).uppercased()
                } else {
                    return nil
                }
        }
    }
}

struct InitialsView_Previews: PreviewProvider {
    static var previews: some View {
        InitialsView(name: "Luca Näf")
    }
}
