//
//  DecryptionResultView.swift
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

struct DecryptionResultView: View {
    var decryptionResult: OpenPGP.DecryptionResult

    var body: some View {
        switch decryptionResult.message {
            case .plain(value: let message):
                Text(message)

            case .mime(value: let mime):
                if let message = try? mime.decodedContentString() {
                    Text(message)
                } else {
                    Text("Failed to decode mime content.")
                        .foregroundColor(.red)
                }
        }
    }
}

struct DecryptionResultView_Previews: PreviewProvider {
    static var decryptionResultPlain = OpenPGP.DecryptionResult(message: .plain(value: ""), signatures: "")

    static var previews: some View {
        DecryptionResultView(decryptionResult: decryptionResultPlain)
    }
}
