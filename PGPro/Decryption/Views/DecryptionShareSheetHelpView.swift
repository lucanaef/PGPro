//
//  DecryptionShareSheetHelpView.swift
//  PGPro
//
//  Created by Luca Näf on 20.02.23.
//

import SwiftUI

struct DecryptionShareSheetHelpView: View {
    var body: some View {
        VStack {
            Spacer()

            Text("Share a file with PGPro")
                .font(.headline)
                .padding()

            VStack(alignment: .leading) {
                Text("1. Tap on the encrypted file")
                Text("2. Tap on '\(Image(systemName: "square.and.arrow.up"))'")
                Text("3. Tap on 'PGPro'")
            }

            Image("share-sheet")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(48.0)
        }
    }
}

struct DecryptionShareSheetHelpView_Previews: PreviewProvider {
    static var previews: some View {
        DecryptionShareSheetHelpView()
    }
}
