//
//  AppearancePreferenceView.swift
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

struct AppearancePreferenceView: View {
    @AppStorage(UserDefaultsKeys.accentColor) var selectedAccentColor: String = Color.accentColor.rawValue

    let selectableColors: [Color] = [
        .pink, .red, .orange, .yellow, .brown,
        .green, .mint, .teal, .cyan, .blue,
        .indigo, .purple, .gray
    ]

    var body: some View {
        Form {
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectableColors, id: \.hashValue) { color in
                            ZStack {
                                RoundedRectangle(cornerRadius: 6.0)
                                    .fill(color)
                                    .border(color, width: 0)
                                    .frame(width: 32, height: 32)
                                    .onTapGesture {
                                        TapticEngine.impact.feedback(.light)
                                        selectedAccentColor = color.rawValue
                                    }

                                RoundedRectangle(cornerRadius: 8.0)
                                    .stroke(color.rawValue == selectedAccentColor ? color : .clear, lineWidth: 3)
                                    .frame(width: 40, height: 40)
                            }
                            .padding(2)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            } header: {
                Text("Accent Colour")
            }
        }
        .navigationTitle("Appearance")
    }
}

struct AppearancePreferenceView_Previews: PreviewProvider {
    static var previews: some View {
        AppearancePreferenceView()
    }
}
