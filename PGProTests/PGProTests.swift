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

    enum PGProTestsError: Error {
        case keyGeneratonError
    }

    override func setUpWithError() throws {
        context = setUpInMemoryManagedObjectContext()
    }

    override func tearDownWithError() throws {
        context = nil
    }

    private func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!

        print(managedObjectModel.entities)

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            print("Adding in-memory persistent store failed")
        }

        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        return managedObjectContext
    }

    func testGenerateKeyNoPassphraseEncryptDecrypt() throws {
        // generate key
        let name = "PGPro 0"
        let email = "0@test.pgpro.app"

        let keyGen = KeyGenerator()
        let key = keyGen.generate(for: email, passphrase: nil)

        // import key
        let contact = Contact(context: context!)
        contact.name = name
        contact.email = email

        do {
            let keyData = try key.export() as NSData
            guard (keyData.length > 0) else {
                throw PGProTestsError.keyGeneratonError
            }
            contact.keyData = keyData
        } catch {
            throw PGProTestsError.keyGeneratonError
        }

        // encrypt and decrypt message
        let message =
        """
        In sequi veniam est nihil exercitationem numquam. Quisquam beatae eos aliquam quo et.
        Aut atque voluptates in doloribus aspernatur error nobis.
        Consequuntur nesciunt deleniti illo vel aut error facilis.
        Non et quos laborum vero debitis. Nihil accusantium est vitae pariatur illo.
        """

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

}
