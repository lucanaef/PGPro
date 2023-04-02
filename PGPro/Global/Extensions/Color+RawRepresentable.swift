//
//  Color+RawRepresentable.swift
//
//  Source: https://gist.github.com/zane-carter/fc2bf8f5f5ac45196b4c9b01d54aca80
//

import Foundation
import SwiftUI
import UIKit

extension Color: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .clear
            return
        }

        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) ?? .clear
            self = Color(color)
        } catch {
            Log.e(error)
            self = .clear
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false) as Data
            return data.base64EncodedString()
        } catch {
            Log.e(error)
            return ""
        }
    }
}
