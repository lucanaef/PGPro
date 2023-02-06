//
//  DecryptionView.swift
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

struct DecryptionView: View {
    @State var decryptionResult: OpenPGP.DecryptionResult?

    var body: some View {
        NavigationView {
            Group {
                VStack {
                    Spacer()

                    Button {
                        #warning("Implement button action.")
                        print("button pressed")
                    } label: {
                        Text("Paste from Clipboard")
                            .frame(maxWidth: .infinity)
                            .frame(height: 20.0)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    HStack {
                        Button {
                            #warning("Implement button action.")
                            print("button pressed")
                        } label: {
                            VStack {
                                Image(systemName: "folder")
                                    .padding(.vertical, 1)
                                Text("Open File")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 30.0)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button {
                            #warning("Implement button action.")
                            print("button pressed")
                        } label: {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .padding(.vertical, 1)
                                Text("Share Menu")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 30.0)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .accentColor(Color.secondary)

                    /*
                    #warning("Implement drag-and-drop area")
                    Label("You can also drag-and-drop a file here.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundColor(Color.secondary)
                     */

                    Spacer()
                }
                .padding(50)
                .background(Color(UIColor.systemGroupedBackground))
                .sheet(item: $decryptionResult) { result in
                    DecryptionResultView(decryptionResult: result)
                }
            }
            .navigationTitle("Decryption")
        }
    }
}

struct DecryptionView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptionView()
    }
}
