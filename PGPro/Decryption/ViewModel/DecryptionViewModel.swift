//
//  DecryptionViewModel.swift
//  PGPro
//
//  Created by Luca Näf on 10.02.23.
//

import Foundation

class DecryptionViewModel: ObservableObject {

    @Published var ciphertext: String?
    @Published var decryptionKey: Set<Contact> = Set()
    @Published var decryptionResult: OpenPGP.DecryptionResult?

}
