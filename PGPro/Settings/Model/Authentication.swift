//
//  Authentication.swift
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
import LocalAuthentication

class Authentication {
    // MARK: - Private

    private init() {}

    private static var context: LAContext {
        let context = LAContext()
        // https://stackoverflow.com/a/37295600
        context.touchIDAuthenticationAllowableReuseDuration = 5
        return context
    }

    private static var biometricAuthenticationAvailable: Bool {
        return Authentication.context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    // MARK: - Public

    static var faceIDAvailable: Bool {
        return  biometricAuthenticationAvailable && context.biometryType == .faceID
    }

    static var touchIDAvailable: Bool {
        return biometricAuthenticationAvailable && context.biometryType == .touchID
    }

    static func requestAuthentication(completion: @escaping (Result<Bool, LAError>) -> Void) {
        let reason = "Launching PGPro requires Authentication."
        /*
        *   Note: The deviceOwnerAuthenticationWithBiometrics policy disallows a passcode fallback
            See `https://developer.apple.com/documentation/localauthentication/logging_a_user_into_your_app_with_face_id_or_touch_id`
        */
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: reason) { (success, error) in
            if let error = error as? LAError {
                completion(.failure(error))
            } else if error != nil {
                completion(.failure(LAError(LAError.systemCancel))) // generic fallback error
            } else {
                completion(.success(success))
            }
        }
    }
}
