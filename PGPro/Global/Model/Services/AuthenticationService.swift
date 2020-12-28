//
//  AuthenticationService.swift
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

class AuthenticationService {

    private init() {}

    private static var context = LAContext()

    private static var biometricsAvailable: Bool {
        return AuthenticationService.context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    static var faceIDAvailable: Bool = {
        return  biometricsAvailable && context.biometryType == .faceID
    }()

    static var touchIDAvailable: Bool = {
        return biometricsAvailable && context.biometryType == .touchID
    }()

    static var symbolName: String = {
        var imageName = "lock"
        if AuthenticationService.touchIDAvailable { imageName = "touchid" }
        if AuthenticationService.faceIDAvailable { imageName = "faceid" }

        return imageName
    }()

    static func requestAuthentication(completion: @escaping (Result<Bool, LAError>) -> Void) {
        let reason = "Launching PGPro requires Authentication."
        context.evaluatePolicy(
            /*
            *   Note: The deviceOwnerAuthenticationWithBiometrics policy disallows a passcode fallback
                See https://developer.apple.com/documentation/localauthentication/logging_a_user_into_your_app_with_face_id_or_touch_id
            */
            LAPolicy.deviceOwnerAuthentication,
            localizedReason: reason) { (success, error) in
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
