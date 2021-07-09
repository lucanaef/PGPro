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

    private let session = YKConnectionSession()

    var version: YKFVersion?
    var formFactor: UInt?
    var serialNumber: UInt?

    var description: String {
        return "Yubikey \(String(describing: serialNumber)) (Version: \(String(describing: version)))"
    }

    // Flags indicating whether or not OpenPGP is supported/enabled over NFC
    var openPGPSupported: Bool?
    var openPGPEnabled: Bool?

    var configurationLocked: Bool?

    // OpenPGP smartcard of the Yubikey
    var smartcard: SmartCard?

    /// Returns true, if the device can support a Yubikey
    static var supportedByDevice: Bool {
        YubiKitDeviceCapabilities.supportsMFIAccessoryKey || YubiKitDeviceCapabilities.supportsNFCScanning
    }

    init() {
        self.fetchConfiguration()

        // MARK: - This method below does not yet work
        //self.fetchSmartCard()

        // Hacky way to make it work async await
        do {
            sleep(3)
        }
    }

    private func fetchConfiguration() {
        session.getConfiguration { result in
            switch result {
            case .success(let response):
                self.version = response.version
                self.formFactor = response.formFactor
                self.serialNumber = response.serialNumber

                if let configuration = response.configuration {
                    self.openPGPSupported = configuration.isSupported(.OPGP, overTransport: .NFC)
                    self.openPGPEnabled = configuration.isEnabled(.OPGP, overTransport: .NFC)

                    self.configurationLocked = configuration.isConfigurationLocked
                } else {
                    Log.e("Configuration not available!")
                }
            case .failure(let error):
                Log.e(error)
            }
        }
    }

    private func fetchSmartCard() {
        session.getCardholder { result in
            switch result {
            case .success(_):
                Log.i("Success!")
            case .failure(let error):
                Log.e(error)
            }
        }
    }

    func logInfo() {
        Log.i("Version: \(String(describing: version))")
        Log.i("Serial Number: \(String(describing: serialNumber))")
        Log.i("Form factor: \(String(describing: formFactor))")
        Log.i("Configuration locked: \(String(describing: configurationLocked))")
        Log.i("OpenPGP supported over NFC: \(String(describing: openPGPSupported))")
        Log.i("OpenPGP enabled over NFC: \(String(describing: openPGPEnabled))")
    }


}
