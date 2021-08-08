//
//  SmartCard.swift
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

/**
 * Data structures modeling the (OpenPGP Smart Card specifications)[https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.pdf]
 */
class SmartCard {

    /**
     Models the YubiKeys' 4 main keys.
     */
    let signatureKey = SmartCardKey()
    let decryptionKey = SmartCardKey()
    let authenticationKey = SmartCardKey()
    let attestationKey = SmartCardKey()

    /**
     * Recurisive initializer that consumes a byte stream according to section 4.4.1 (DOs for GET DATA) of
     *   the (OpenPGP Smart Card specifications)[https://gnupg.org/ftp/specs/OpenPGP-smart-card-application-3.4.pdf]
     */
    init(from data: Data) { recursiveInit(from: data) }
    private func recursiveInit(from data: Data) {
        // Base case of recursive initalizer
        if data.isEmpty { return }

        let tag: UInt8 = data[0]
        switch tag {
        case 0x6e: // Application related data
            let announcedLength = Int((UInt16(data[2]) << 8) + UInt16(data[3]))
            let headerLength = 4 // i.e. 6e 82  01 37
            guard (announcedLength + headerLength == data.count) else {
                Log.e("Application related data length mismatch (announced: \(announcedLength + 4); received: \(data.count))")
                return
            }
            recursiveInit(from: Data(data.dropFirst(4)))
        case 0x4f: // Application identifier (AID)
            // Log.i("Application identifier (AID): \(data[1...17].hexEncodedString)")
            recursiveInit(from: Data(data.dropFirst(18)))
        case 0x5f: // Historial bytes
            if (data[1] == 0x52) {
                // Log.i("Historial bytes: \(data[2...10].hexEncodedString)")
                recursiveInit(from: Data(data.dropFirst(11)))
            } else {
                Log.e("Unrecognized data packet: \(data.hexEncodedString)")
                return
            }
        case 0x7f:
            if (data[1] == 0x74) { // General feature management (optional)
                // Log.i("General feature management: \(data[2...5].hexEncodedString)")
                recursiveInit(from: Data(data.dropFirst(6)))
            } else if (data[1] == 0x66) { // Extended length information
                // Log.i("Extended length information: \(data[2...10].hexEncodedString)")
                recursiveInit(from: Data(data.dropFirst(11)))
            } else {
                Log.e("Unrecognized data packet: \(data.hexEncodedString)")
                return
            }
        case 0x73: // Discretionary data objects
            // Log.i("Discretionary data objects: \(data[1...3].hexEncodedString)")
            recursiveInit(from: Data(data.dropFirst(4)))
        case 0xc0: // Extended capabilities
            // Log.i("Extended capabilities: \(data[1...11].hexEncodedString)")
            recursiveInit(from: Data(data.dropFirst(12)))
        case 0xc1: // Algorithm attributes signature
            Log.i("Data: \(data.hexEncodedString)")

            let length = Int(UInt8(data[1]))

            switch data[2] {
            case 0x01:
                signatureKey.algorithmAttributes = SmartCardKey.AlgorithmAttributesRSA(from: Data(data[2...(length+1)]))
            case 0x12, 0x13:
                signatureKey.algorithmAttributes = SmartCardKey.AlgorithAttributesECDSA(from: Data(data[2...(length+1)]))
            default:
                Log.i("Algorithm attributes signature: \(data[1...(length+1)].hexEncodedString)")
                Log.e("Invalid Key Algorithm ID.")
                return
            }
            recursiveInit(from: Data(data.dropFirst(length + 2)))
        case 0xc2: // Algorithm attributes decryption
            let length = Int(UInt8(data[1]))

            switch data[2] {
            case 0x01:
                decryptionKey.algorithmAttributes = SmartCardKey.AlgorithmAttributesRSA(from: Data(data[2...(length+1)]))
            case 0x12, 0x13:
                decryptionKey.algorithmAttributes = SmartCardKey.AlgorithAttributesECDSA(from: Data(data[2...(length+1)]))
            default:
                Log.i("Algorithm attributes signature: \(data[1...(length+1)].hexEncodedString)")
                Log.e("Invalid Key Algorithm ID.")
                return
            }
            recursiveInit(from: Data(data.dropFirst(length + 2)))
        case 0xc3: // Algorithm Decryption authentication
            let length = Int(UInt8(data[1]))

            switch data[2] {
            case 0x01:
                authenticationKey.algorithmAttributes = SmartCardKey.AlgorithmAttributesRSA(from: Data(data[2...(length+1)]))
            case 0x12, 0x13:
                authenticationKey.algorithmAttributes = SmartCardKey.AlgorithAttributesECDSA(from: Data(data[2...(length+1)]))
            default:
                Log.i("Algorithm attributes signature: \(data[1...(length+1)].hexEncodedString)")
                Log.e("Invalid Key Algorithm ID.")
                return
            }
            recursiveInit(from: Data(data.dropFirst(length + 2)))
        case 0xda: // Algorithm attributes Attestation key (Yubico)
            let length = Int(UInt8(data[1]))

            switch data[2] {
            case 0x01:
                attestationKey.algorithmAttributes = SmartCardKey.AlgorithmAttributesRSA(from: Data(data[2...(length+1)]))
            case 0x12, 0x13:
                attestationKey.algorithmAttributes = SmartCardKey.AlgorithAttributesECDSA(from: Data(data[2...(length+1)]))
            default:
                Log.i("Algorithm attributes signature: \(data[1...(length+1)].hexEncodedString)")
                Log.e("Invalid Key Algorithm ID.")
                return
            }
            recursiveInit(from: Data(data.dropFirst(length + 2)))
        case 0xc4: // PW Status Bytes
            // Log.i("PW Status Bytes: \(data[1...8].hexEncodedString)")
            recursiveInit(from: Data(data.dropFirst(9)))
        case 0xc5: // Fingerprints (20 bytes (dec.) each)
            guard data[1] == 0x50 else {
                Log.i("Fingerprints (20 bytes (dec.) each): \(data[1...81].hexEncodedString)")
                Log.e("Announced length doesn't match expected length.")
                return
            }

            signatureKey.fingerprint = SmartCardKey.Fingerprint(from: Data(data[2...21]))
            decryptionKey.fingerprint = SmartCardKey.Fingerprint(from: Data(data[22...41]))
            authenticationKey.fingerprint = SmartCardKey.Fingerprint(from: Data(data[42...61]))
            attestationKey.fingerprint = SmartCardKey.Fingerprint(from: Data(data[62...81]))

            recursiveInit(from: Data(data.dropFirst(82)))
        case 0xc6: // CA-Fingerprints (20 bytes (dec.) each)
            // Log.i("CA-Fingerprints (20 bytes (dec.) each): \(data[1...81].hexEncodedString)")
            recursiveInit(from: Data(data.dropFirst(82)))
        case 0xcd: // List of generation dates/times of key pairs (4 bytes (dec.) each)
            // Log.i("List of generation dates/times of key pairs: \(data[1...17].hexEncodedString)")
            recursiveInit(from: Data(data.dropFirst(18)))
        case 0xde: // Key Information (2 bytes (dec.) each)
            guard data[1] == 0x08 else {
                Log.i("Key Information: \(data[1...9].hexEncodedString)")
                Log.e("Invalid length.")
                return
            }
            recursiveInitKeyInformation(from: Data(data[2...9]))
            recursiveInit(from: Data(data.dropFirst(10)))
        case 0xd6: // User Interaction Flag (UIF) for PSO:CDS
            // Log.i("UIF for PSO:CDS: \(data[1...3].hexEncodedString)")
            signatureKey.userInteractionFlag = SmartCardKey.UserInteractionFlag(rawValue: UInt8(data[2]))
            recursiveInit(from: Data(data.dropFirst(4)))
        case 0xd7: // User Interaction Flag (UIF) for PSO:DEC
            // Log.i("UIF for PSO:DEC: \(data[1...3].hexEncodedString)")
            decryptionKey.userInteractionFlag = SmartCardKey.UserInteractionFlag(rawValue: UInt8(data[2]))
            recursiveInit(from: Data(data.dropFirst(4)))
        case 0xd8: // User Interaction Flag (UIF) for PSO:AUT
            // Log.i("UIF for PSO:AUT: \(data[1...3].hexEncodedString)")
            authenticationKey.userInteractionFlag = SmartCardKey.UserInteractionFlag(rawValue: UInt8(data[2]))
            recursiveInit(from: Data(data.dropFirst(4)))
        case 0xd9: // UIF for Attestation key and Generate Attestation command (Yubico)
            // Log.i("UIF for PSO:ATT: \(data[1...3].hexEncodedString)")
            attestationKey.userInteractionFlag = SmartCardKey.UserInteractionFlag(rawValue: UInt8(data[2]))
            recursiveInit(from: Data(data.dropFirst(4)))
        default:
            Log.e("Unrecognized data packet: \(data.hexEncodedString)")
            return
        }
    }

    private func recursiveInitKeyInformation(from data: Data) {
        if data.isEmpty { return } // Base case of recursive initalizer

        switch data[0] {
        case 0x01:
            signatureKey.status = SmartCardKey.KeyStatus(rawValue: UInt8(data[1]))
            recursiveInitKeyInformation(from: Data(data.dropFirst(2)))
        case 0x02:
            decryptionKey.status = SmartCardKey.KeyStatus(rawValue: UInt8(data[1]))
            recursiveInitKeyInformation(from: Data(data.dropFirst(2)))
        case 0x03:
            authenticationKey.status = SmartCardKey.KeyStatus(rawValue: UInt8(data[1]))
            recursiveInitKeyInformation(from: Data(data.dropFirst(2)))
        case 0x81:
            attestationKey.status = SmartCardKey.KeyStatus(rawValue: UInt8(data[1]))
            recursiveInitKeyInformation(from: Data(data.dropFirst(2)))
        default:
            Log.e("Invalid Key-Ref")
            return
        }
    }

    var cardholder: Cardholder?
    class Cardholder {
        var name: String?
        var language: String?
        var sex: String?

        init?(from data: Data) {
            guard data[0] == 0x65 else {
                return nil // wrong tag
            }

            // Decore and parse name data (Section 4.4.3.3; OpenPGP-smart-card-application-3.4.pdf)
            if data[2] == 0x5b {
                let nameLength = Int(data[3])
                let nameRange: ClosedRange = 4...(4+nameLength)
                let nameData = data.subdata(in: Range<Data.Index>(nameRange))

                if let name = String(data: nameData, encoding: .isoLatin1) {
                    let nameComponents = name.components(separatedBy: "<<").map { String($0) }
                    if nameComponents.count > 0 {
                        let surname = nameComponents[0]
                        if nameComponents.count > 1 {
                            let forenames = nameComponents[1]
                            self.name = forenames.replacingOccurrences(of: "<", with: " ").replacingOccurrences(of: "_", with: " ")
                        }
                        if self.name == nil {
                            self.name = surname
                        }
                        self.name = self.name!.appending(surname)
                    }
                }
            } // else skip name

            // TODO: - Parse language and sex (?)

        }
    }

}
