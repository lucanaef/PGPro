//
//  AuthenticationPreferenceViewModel.swift
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

enum AuthenticationPreferenceViewModel {
    static var symbolName: String {
        var imageName = "lock"

        if Authentication.touchIDAvailable {
            imageName = "touchid"
        }

        if Authentication.faceIDAvailable {
            imageName = "faceid"
        }

        return imageName
    }

    static var isAvailable: Bool {
        Authentication.faceIDAvailable || Authentication.touchIDAvailable
    }
}
