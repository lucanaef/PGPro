//
//  PlaceholderTextEditor.swift
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

struct PlaceholderTextEditor: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack {
            TextEditor(text: $text)
                .foregroundColor(.primary)

            TextEditor(text: .constant(placeholder))
                .disabled(true)
                .foregroundColor(.primary)
                .opacity(text.isEmpty ? 0.25 : 0)
        }
    }
}

struct PlaceholderTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderTextEditor(placeholder: "Placeholder...", text: .constant(""))
    }
}
