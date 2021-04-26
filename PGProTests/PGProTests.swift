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

import XCTest
import CoreData
import ObjectivePGP
@testable import PGPro

class PGProTests: XCTestCase {

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
            guard (keyData.length > 0) else {
                throw PGProTestsHelper.TestsError.keyGeneratonError
            }
            contact.keyData = keyData
        } catch {
            throw PGProTestsHelper.TestsError.keyGeneratonError
        }

        /// Encrypt and decrypt message
        let message = PGProTestsHelper.randomString(of: 2048)

        do {
            let encryptedMessage = try CryptographyService.encrypt(message: message, for: [contact])

            do {
                let decryptedMessage = try CryptographyService.decrypt(message: encryptedMessage, by: contact, withPassphrase: nil)

                XCTAssertEqual(message, decryptedMessage)

            } catch (let error) {
                throw error
            }

        } catch (let error) {
            throw error
        }

    }

    private func importEncryptDecrypt(id: Int, from url: URL, passphrase: String?, for message: String? = nil, isSupported: Bool = true) throws {
        do {
            /// Check that supported keys are supported
            if isSupported {
                XCTAssertNoThrow(try KeyConstructionService.fromFile(fileURL: url))
            } else {
                XCTAssertThrowsError(try KeyConstructionService.fromFile(fileURL: url))
            }

            /// Import key from file
            let keys = try KeyConstructionService.fromFile(fileURL: url)
            let key = keys.first!

            /// Construct contact from key
            let contact = Contact(context: context!)
            contact.name = "PGPro \(id)"
            contact.email = "\(id)@test.pgpro.app"

            do {
                let keyData = try key.export() as NSData
                guard (keyData.length > 0) else {
                    throw PGProTestsHelper.TestsError.keyGeneratonError
                }
                contact.keyData = keyData
            } catch {
                throw PGProTestsHelper.TestsError.keyGeneratonError
            }

            /// If necessary, generate random message
            let message: String = message ?? PGProTestsHelper.randomString(of: Int.random(in: 0...10000))

            /// Encrypt and decrypt message
            do {
                let encryptedMessage = try CryptographyService.encrypt(message: message, for: [contact])

                do {
                    let decryptedMessage = try CryptographyService.decrypt(message: encryptedMessage, by: contact, withPassphrase: passphrase)

                    XCTAssertEqual(message, decryptedMessage)

                } catch (let error) {
                    throw error
                }

            } catch (let error) {
                throw error
            }


        } catch (let error) {
            throw error
        }
    }

    func testImportEncryptDecrypt() throws {
        for key in PGProTestsKeys.keys {
            do {
                try importEncryptDecrypt(id: key.id, from: key.url, passphrase: key.passphrase, isSupported: key.isSupported)
            } catch (let error) {
                throw error
            }
        }
    }

}
