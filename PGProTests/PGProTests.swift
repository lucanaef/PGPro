//
//  PGProTests.swift
//  PGProTests
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

import CoreData
import ObjectivePGP
@testable import PGPro
import XCTest

final class PGProTests: XCTestCase {
    var context: NSManagedObjectContext?

    override func setUpWithError() throws {
        context = PGProTestsHelper.setUpInMemoryManagedObjectContext()
    }

    override func tearDownWithError() throws {
        context = nil
    }

    func testGenerateKeyNoPassphraseEncryptDecrypt() throws {
            /// Generate key
        let name = "PGPro 0"
        let email = "0@test.pgpro.app"

        let keyGen = KeyGenerator()
        let key = keyGen.generate(for: email, passphrase: nil)

            /// Import key
        let contact = Contact(context: context!)
        contact.name = name
        contact.email = email

        do {
            let keyData = try key.export() as NSData
            guard keyData.length > 0 else {
                throw PGProTestsHelper.TestsError.keyGeneratonError
            }
            contact.keyData = keyData
        } catch {
            throw PGProTestsHelper.TestsError.keyGeneratonError
        }

            /// Encrypt and decrypt message
        let message = PGProTestsHelper.randomString(of: 2_048)
        do {
            let encryptedMsg = try OpenPGP.encrypt(message: message, for: [contact])
            let decryptedMsg = try OpenPGP.decrypt(message: encryptedMsg, for: contact, withPassphrase: nil)
            XCTAssertEqual(message, decryptedMsg.plaintext)
        } catch {
            throw error
        }
    }
}
