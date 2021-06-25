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
import YubiKit // for YKFAPDU

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
        static var changeRefData: UInt8     = 0x24
        static var resetRetryCounter: UInt8 = 0x2C
        // TODO: Whis one is it? DA or DB? Specifications unclear to me...
        //static var putData: UInt8           = 0xDA 0xDB
        static var generateAsymPair: UInt8  = 0x47
        static var computeDigSig: UInt8     = 0x2A
        static var decipher: UInt8          = 0x2A
        static var internalAuth: UInt8      = 0x88
        static var getResponse: UInt8       = 0xC0
        static var getChallenge: UInt8      = 0x84
        static var terminateDF: UInt8       = 0x44
        static var activateFile: UInt8      = 0xE6
    }

    /// Terminal-accessible, get-able OpenPGP smart card Data Object tags
    private struct DataObjects {
        private init() {}

        struct Simple {
            private init() {}

            static var applicationIdentifier: UInt8     = 0x4F
            static var loginData: UInt8                 = 0x5E
            static var publicKeyURL: UInt16             = 0x5F50
            static var historicalBytes: UInt16          = 0x5F52
            static var pwStatus: UInt8                  = 0xC4
            static var keyInfo: UInt8                   = 0xDE
        }

        struct Constructed {
            private init() {}

            static var cardholderData: UInt8            = 0x65
            static var applicationData: UInt8           = 0x6E
            static var securitySupportTemplate: UInt8   = 0x7A
        }
    }

    // MARK: - Public APDU Commands

    static var selectOpenPGPApplet = YKFAPDU(cla: Class.singleWithoutSM, // 0x00
                                             ins: Ins.select, // 0xA4
                                             p1: 0x04, p2: 0x00,
                                             data: Data([0xD2, 0x76, 0x00, 0x01, 0x24, 0x01]),
                                             type: YKFAPDUType.short)!

    static var selectOpenPGPApplet2 = YKFSelectApplicationAPDU(data: Data([0xD2, 0x76, 0x00, 0x01, 0x24, 0x01]))!

    // TODO: Ideally use Secure Messaging for this command here (?)
    static var getCardholderData = YKFAPDU(cla: Class.singleWithoutSM,
                                           ins: Ins.getData,
                                           p1: 0x00, p2: DataObjects.Constructed.cardholderData,
                                           data: Data(),
                                           type: YKFAPDUType.short)! // since data doesn't exceed 256 bytes

    static var getKeyInformation = YKFAPDU(cla: Class.singleWithoutSM,
                                           ins: Ins.getData,
                                           p1: 0x00, p2: DataObjects.Simple.keyInfo,
                                           data: Data(),
                                           type: YKFAPDUType.short)!

}
