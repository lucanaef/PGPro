//
//  Yubikey.swift
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

class Yubikey {

    private var pin: String

    var version: YKFVersion?
    var formFactor: UInt?
    var serialNumber: UInt?

    var description: String {
        return "Yubikey \(String(describing: serialNumber)) (Version \(String(describing: version)))"
    }

    // Indicated whether or not OpenPGP is supported/enabled over NFC
    struct OpenPGPCapabilities {
        enum OpenPGPStatus {
            case notSupported
            case disabled
            case enabled

            init(supported: Bool, enabled: Bool) {
                if !supported {
                    self = .notSupported
                } else if enabled {
                    self = .enabled
                } else {
                    self = .disabled
                }
            }
        }

        var NFC: OpenPGPStatus
        var Accessory: OpenPGPStatus
        var locked: Bool
    }
    var capabilities: OpenPGPCapabilities?


    /// Returns true, if the device can support a Yubikey
    static var supportedByDevice: Bool {
        YubiKitDeviceCapabilities.supportsMFIAccessoryKey || YubiKitDeviceCapabilities.supportsNFCScanning
    }

    init?(pin: String) {
        self.pin = pin
        do {
            try self.fetchConfiguration()
        } catch {
            return nil
        }
    }

    private func fetchConfiguration() throws {
        let semaphore = DispatchSemaphore(value: 0)

        let session = YKConnectionSession()
        session.getConfiguration { result in
            switch result {
            case .success(let response):
                self.version = response.version
                self.formFactor = response.formFactor
                self.serialNumber = response.serialNumber

                if let configuration = response.configuration {
                    let nfc = OpenPGPCapabilities.OpenPGPStatus(supported: configuration.isSupported(.OPGP, overTransport: .NFC),
                                                                enabled: configuration.isEnabled(.OPGP, overTransport: .NFC))
                    let accessory = OpenPGPCapabilities.OpenPGPStatus(supported: configuration.isSupported(.OPGP, overTransport: .USB),
                                                                      enabled: configuration.isEnabled(.OPGP, overTransport: .USB))

                    self.capabilities = OpenPGPCapabilities(NFC: nfc, Accessory: accessory, locked: configuration.isConfigurationLocked)
                } else {
                    Log.e("Configuration not available!")
                }
            case .failure(let error):
                Log.e(error)
            }
            semaphore.signal()
        }

        if semaphore.wait(timeout: .now() + 7) == .timedOut {
            session.stop()
            throw YKError.timeout
        }

        session.stop()
    }

    open func getKeyInformation(completion: @escaping (Result<SmartCard.KeyInformation, Error>) -> Void) {
        let session = YKConnectionSession()
        session.getKeyInformation(pin: pin) { result in
            completion(result)
            session.stop()
        }
    }

}
