//
//  YKConnectionSession.swift
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

public enum YKError: Error, CustomStringConvertible {
    case smartcardNotAvailable
    case smartcardError(status: UInt16)
    case unrecognizedKeyAttributes
    case nilExecutionResponse
    case failedToBuildAPDU
    case failedToDecipher
    case notImplemented
    case invalidInput
    case invalidResponse
    case invalidPIN
    case timeout

    public var description: String {
        switch self {
        case .smartcardNotAvailable: return "rawCommandService is not available"
        case .smartcardError(let status): return "RawCommandService Status: \(statusDescription(of: status))"
        case .unrecognizedKeyAttributes: return "Unrecognized Key Attributes"
        case .nilExecutionResponse: return "Empty NFC execution response"
        case .failedToBuildAPDU: return "Failed to build APDU"
        case .failedToDecipher: return "Failed to decipher"
        case .notImplemented: return "Not Implemented"
        case .invalidInput: return "Invalid Input"
        case .invalidResponse: return "Invalid Response"
        case .invalidPIN: return "Invalid PIN"
        case .timeout: return "Timeout"
        }
    }

    /**
    Returns a string describing a given OpenPGP smart card status code
     */
    func statusDescription(of status: UInt16) -> String {
        let sw1 = UInt8(status >> 8)
        let sw2 = UInt8(status & 0x00FF)

        // Special cases (commented out below)
        if (sw1 == 0x61) {
            return "Command correct, \(sw2) bytes available in response"
        } else if (sw1 == 0x63) {
            let retries = UInt8((sw2 >> 4) & 0x000F)
            return "Password not checked, \(retries) further allowed retries"
        } else if (status >= 0x6280) && (status <= 0x6402) {
            return "Triggering by the card; 0E = Out of Memory (BasicCard specific)"
        }

        switch status {
        // case: 0x61XX: return "Command correct, xx bytes available in response"
        case 0x6285: return "Selected file or DO in termination state"
        // case 0x63CX: return "Password not checked, 'X' encodes the number of further allowed retries"
        // case 0x6402-0x6280: return "Triggering by the card; 0E = Out of Memory (BasicCard specific)"
        case 0x6581: return "Memory failure"
        case 0x6600: return "Security-related issues"
        case 0x6700: return "Wrong length (Lc and/or Le)"
        case 0x6881: return "Logical channel not supported"
        case 0x6882: return "Secure messaging not supported"
        case 0x6883: return "Last command of the chain expected"
        case 0x6884: return "Command chaining not supported"
        case 0x6982: return "Security status not satisfied (PW wrong/PW not checked/SM incorrect)"
        case 0x6983: return "Authentication method blocked; PW blocked (error counter zero)"
        case 0x6985: return "Condition of use not satisfied"
        case 0x6987: return "Expected secure messaging DOs missing (e. g. SM-key)"
        case 0x6988: return "SM data objects incorrect (e. g. wrong TLV-structure in command data)"
        case 0x6A80: return "Incorrect parameters in the command data field"
        case 0x6A82: return "File or application not found"
        case 0x6A88: return "Referenced data, reference data or DO not found"
        case 0x6B00: return "Wrong parameters P1-P2"
        case 0x6D00: return "Instruction code (INS) not supported or invalid"
        case 0x6E00: return "Class (CLA) not supported"
        case 0x6F00: return "No precise diagnosis"
        case 0x9000: return "Command correct"
        default:     return "Other status code: \(String(format:"%02X", status))"
        }
     }
}

class YKConnectionSession: NSObject, ObservableObject, YKFManagerDelegate {

    // MARK: - Connection handling
    // According to https://github.com/Yubico/yubikit-ios/blob/master/docs/easy-handling-connections.md

    override init() {
        super.init()
        YubiKitManager.shared.delegate = self
        if (YubiKitDeviceCapabilities.supportsMFIAccessoryKey) {
            YubiKitManager.shared.startAccessoryConnection()
        } else {
            Log.e("YubiKitDeviceCapabilities.supportsMFIAccessoryKey returned false: Unsupproted Device!")
        }
    }

    private var nfcConnection: YKFNFCConnection?
    private var accessoryConnection: YKFAccessoryConnection?

    func didConnectNFC(_ connection: YKFNFCConnection) {
        nfcConnection = connection
        if let callback = connectionCallback {
            callback(connection)
        }
    }

    func didDisconnectNFC(_ connection: YKFNFCConnection, error: Error?) {
        nfcConnection = nil
    }

    func didConnectAccessory(_ connection: YKFAccessoryConnection) {
        accessoryConnection = connection
    }

    func didDisconnectAccessory(_ connection: YKFAccessoryConnection, error: Error?) {
        accessoryConnection = nil
    }

    func stop() {
        YubiKitManager.shared.stopAccessoryConnection()
        YubiKitManager.shared.stopNFCConnection()
        YubiKitManager.shared.delegate = nil
    }


    // MARK: - Connection helper functions

    private var connectionCallback: ((_ connection: YKFConnectionProtocol) -> Void)?
    private func getConnection(completion: @escaping (_ connection: YKFConnectionProtocol) -> Void) {
        if let connection = accessoryConnection {
            completion(connection)
        } else {
            connectionCallback = completion
            if (YubiKitDeviceCapabilities.supportsISO7816NFCTags) {
                YubiKitManager.shared.startNFCConnection()
            } else {
                Log.e("YubiKitDeviceCapabilities.supportsISO7816NFCTags returned false: Unsupported Device!")
            }
        }
    }

    private func closeConnection() {
        YubiKitManager.shared.stopAccessoryConnection()
        YubiKitManager.shared.stopNFCConnection()
    }

    // MARK: - Public functions

    /**
     Establishes a new connection to the YubiKey and fetches its configuration from the management application.
    */
    open func getConfiguration(completion: @escaping (Result<YKFManagementReadConfigurationResponse, Error>) -> Void) {
        getConnection { connection in
            connection.managementSession { (session, error) in
                if let session = session {
                    session.readConfiguration { (response, error) in
                        if let response = response {
                            completion(.success(response))
                        } else if let error = error {
                            completion(.failure(error))
                        } else {
                            Log.s("Unknown error occured while reading configuration.")
                        }
                    }
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    Log.s("Unknown error occured while establishing the management session.")
                }
            }
        }
    }

    /**
     Establishes a new connection to the YubiKey and fetches the smart card information from the OpenPGP applet.
    */
    open func getSmartCard(pin: String, completion: @escaping (Result<SmartCard, Error>) -> Void) {
        getConnection { connection in
            guard let smartcard = connection.smartCardInterface else {
                completion(.failure(YKError.smartcardNotAvailable))
                return
            }

            // Select the OpenPGP applet:
            smartcard.executeCommand(APDU.selectOpenPGPApplet) { (data, error) in
                if let error = error {
                    let statuscode = (error as NSError).code
                    completion(.failure(YKError.smartcardError(status: UInt16(statuscode))))
                    return
                }

                // Parse response from smart card (0 byte data expected)
                guard data != nil else {
                    completion(.failure(YKError.nilExecutionResponse))
                    return
                }
                // OpenPGP application selected!

                // Verify Pin:
                guard let verifyPINAPDU = APDU.verfiyPIN(pin: pin) else {
                    completion(.failure(YKError.invalidPIN))
                    return
                }

                smartcard.executeCommand(verifyPINAPDU) { (data, error) in
                    guard error == nil else {
                        Log.e("PIN verification failed!")
                        completion(.failure(YKError.invalidPIN))
                        return
                    }
                    // PIN verification successful!

                    // Request key information:
                    smartcard.executeCommand(APDU.getApplicationData) { (data, error) in
                        if let error = error {
                            let statuscode = (error as NSError).code
                            completion(.failure(YKError.smartcardError(status: UInt16(statuscode))))
                            return
                        }

                        guard let data = data else {
                            completion(.failure(YKError.nilExecutionResponse))
                            return
                        }

                        Log.i(data.hexEncodedString)


                        let smartCard = SmartCard(from: data)
                        completion(.success(smartCard))
                    }
                }
            }
        }
    }

    /**
     Establishes a new connection to the YubiKey and fetches the cardholder related data from the OpenPGP applet.
    */
    open func getCardholderData(pin: String, completion: @escaping (Result<SmartCard.Cardholder, Error>) -> Void) {
        getConnection { connection in
            guard let smartcard = connection.smartCardInterface else {
                completion(.failure(YKError.smartcardNotAvailable))
                return
            }

            /// (Synchronously) select the OpenPGP Applet
            smartcard.executeCommand(APDU.selectOpenPGPApplet) { (data, error) in
                if let error = error {
                    let statuscode = (error as NSError).code
                    completion(.failure(YKError.smartcardError(status: UInt16(statuscode))))
                    return
                }

                // Parse response from smart card (0 byte data expected)
                guard data != nil else {
                    completion(.failure(YKError.nilExecutionResponse))
                    return
                }
                // OpenPGP application selected!

                // Verify Pin
                guard let verifyPINAPDU = APDU.verfiyPIN(pin: pin) else {
                    completion(.failure(YKError.invalidPIN))
                    return
                }

                smartcard.executeCommand(verifyPINAPDU) { (data, error) in
                    guard error == nil else {
                        Log.e("PIN verification failed!")
                        completion(.failure(YKError.invalidPIN))
                        return
                    }
                    // PIN verification successful!

                    // Request key information
                    smartcard.executeCommand(APDU.getCardholderData) { (data, error) in
                        if let error = error {
                            let statuscode = (error as NSError).code
                            completion(.failure(YKError.smartcardError(status: UInt16(statuscode))))
                            return
                        }

                        guard let data = data else {
                            completion(.failure(YKError.nilExecutionResponse))
                            return
                        }

                        let cardholder = SmartCard.Cardholder(from: data)
                        if let cardholder = cardholder {
                            completion(.success(cardholder))
                        } else {
                            completion(.failure(YKError.invalidResponse))
                        }
                    }
                }
            }
        }
    }


    open func decipher(ciphertext: String, pin: String, completion: @escaping (Result<String, Error>) -> Void) {
        getConnection { connection in
            guard let smartcard = connection.smartCardInterface else {
                completion(.failure(YKError.smartcardNotAvailable))
                return
            }

            // Select the OpenPGP applet:
            smartcard.executeCommand(APDU.selectOpenPGPApplet) { (data, error) in
                if let error = error {
                    let statuscode = (error as NSError).code
                    completion(.failure(YKError.smartcardError(status: UInt16(statuscode))))
                    return
                }

                // Parse response from smart card (0 byte data expected)
                guard data != nil else {
                    completion(.failure(YKError.nilExecutionResponse))
                    return
                }
                // OpenPGP application selected!

                // Verify Pin:
                guard let verifyPINAPDU = APDU.verfiyPIN(pin: pin) else {
                    completion(.failure(YKError.invalidPIN))
                    return
                }

                smartcard.executeCommand(verifyPINAPDU) { (data, error) in
                    guard error == nil else {
                        Log.e("PIN verification failed!")
                        completion(.failure(YKError.invalidPIN))
                        return
                    }
                    // PIN verification successful!

                    // Request key information
                    smartcard.executeCommand(APDU.getApplicationData) { (data, error) in
                        if let error = error {
                            let statuscode = (error as NSError).code
                            completion(.failure(YKError.smartcardError(status: UInt16(statuscode))))
                            return
                        }

                        guard let data = data else {
                            completion(.failure(YKError.nilExecutionResponse))
                            return
                        }


                        let smartCard = SmartCard(from: data)
                        let keyAttributes = smartCard.decryptionKey.algorithmAttributes

                        guard let algorithmID = keyAttributes?.algorithmID else {
                            completion(.failure(YKError.unrecognizedKeyAttributes))
                            return
                        }

                        switch keyAttributes {
                        case let keyAttributesRSA as SmartCardKey.AlgorithmAttributesRSA:
                            Log.d("RSA key: \(keyAttributesRSA)")


                            // Decode amored message
                            var ciphertextData = Data() // this line is just here to calm down the compiler
                            do {
                                ciphertextData = try CryptographyService.dearmor(message: ciphertext)
                            } catch (let parsingError) {
                                Log.e(parsingError)
                                completion(.failure(YKError.invalidInput))
                                return
                            }

                            // TODO: Extract session key and decrypt it using yubikey smart card

                            guard let decipherAPDU = APDU.decipherAPDU(ciphertext: ciphertextData, keyType: algorithmID) else {
                                completion(.failure(YKError.failedToBuildAPDU))
                                return
                            }

                            smartcard.executeCommand(decipherAPDU) { (data, error) in
                                guard error == nil else {
                                    Log.e("Deciphering failed!")
                                    completion(.failure(YKError.failedToDecipher))
                                    return
                                }

                                guard let data = data, let plaintext = String(bytes: data, encoding: .utf8) else {
                                    Log.d("Data: \(String(describing: data))")
                                    completion(.failure(YKError.invalidResponse))
                                    return
                                }

                                completion(.success(plaintext))
                                return
                            }
                        case let keyAttributesECDSA as SmartCardKey.AlgorithAttributesECDSA:
                            Log.d("ECC key: \(keyAttributesECDSA)")
                            completion(.failure(YKError.notImplemented))
                        default:
                            completion(.failure(YKError.unrecognizedKeyAttributes))
                        }

                    }

                    // TODO: Decrypt ciphertext
                }
            }
        }
    }
}