//
//  APDU.swift
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

import Foundation
import YubiKit

struct APDU {
    private init() {}

    // MARK: - Private ISO/IEC 7816-4 APDU Data model

    private struct Class {
        private init() {}

        static var singleWithoutSM: UInt8   = 0x00
        static var singleWithSM: UInt8      = 0x0C
        static var chainedWithoutSM: UInt8  = 0x10
        static var chainedWithSM: UInt8     = 0x1C
    }

    private struct Ins {
        private init() {}

        static var select: UInt8            = 0xA4
        static var getData: UInt8           = 0xCA
        static var verify: UInt8            = 0x20
        static var resetRetryCounter: UInt8 = 0x2C
        static var decipher: UInt8          = 0x2A
    }

    /// Terminal-accessible, get-able OpenPGP smart card Data Object tags
    private struct DataObjects {
        private init() {}

        // Single
        static var keyInfo: UInt8           = 0xDE

        struct publicKeyURL {
            private init() {}

            static var P1: UInt8            = 0x5F
            static var P2: UInt8            = 0x50
        }

        // Constructed
        static var cardholderData: UInt8    = 0x65
        static var applicationData: UInt8   = 0x6E
    }

    // MARK: - Public APDU Commands

    static var selectOpenPGPApplet = YKFAPDU(data: Data([Class.singleWithoutSM, Ins.select, 0x04, 0x00, 0x06, 0xD2, 0x76, 0x00, 0x01, 0x24, 0x01]))!

    static var getApplicationData = YKFAPDU(data: Data([Class.singleWithoutSM, Ins.getData, 0x00, DataObjects.applicationData, 0x00]))!

    static var getCardholderData = YKFAPDU(data: Data([Class.singleWithoutSM, Ins.getData, 0x00, DataObjects.cardholderData, 0x00]))!

    static var getKeyInformation = YKFAPDU(data: Data([Class.singleWithoutSM, Ins.getData, 0x00, DataObjects.keyInfo, 0x00]))!

    static var getKeyURL = YKFAPDU(cla: Class.singleWithoutSM, ins: Ins.getData, p1: DataObjects.publicKeyURL.P1, p2: DataObjects.publicKeyURL.P2, data: Data(), type: .short)!

    static func verfiyPIN(pin: String) -> YKFAPDU? {
        guard let pinData = pin.data(using: .utf8) else {
            return nil
        }

        var verifyPINCommand = Data([Class.singleWithoutSM, Ins.verify, 0x00, 0x82])
        verifyPINCommand.append(UInt8(pinData.count))
        verifyPINCommand.append(pinData)

        return YKFAPDU(data: verifyPINCommand)
    }

    static func decipherAPDU(ciphertext: Data, keyType: SmartCardKey.AlgorithmAttributes.AlgorithmAttributesID) -> YKFAPDU? {
        guard let ciphertextLength = UInt8(exactly: ciphertext.count) else {
            Log.e("Ciphertext length (\(ciphertext.count)) not convertible to UTF8.")
            return nil
        }

        switch keyType {
        case .RSA:
            var decipherAPDU = Data([Class.singleWithoutSM, Ins.decipher, 0x80, 0x86, ciphertextLength])

            decipherAPDU.append(Data([00])) // Padding indicator byte (00) for RSA
            decipherAPDU.append(ciphertext)
            decipherAPDU.append(Data([00])) // Le

            return YKFAPDU(data: decipherAPDU)
        case .ECDH:
            Log.e("ECDH deciphering not implemented")
            return nil
        case .ECDSA:
            Log.e("ECDSA deciphering not implemented")
            return nil
        }
    }

}
