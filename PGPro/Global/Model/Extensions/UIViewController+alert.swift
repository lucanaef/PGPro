//
//  UIViewController+alert.swift
//  PGPro
//

import Foundation
import UIKit
import SPAlert

extension UIViewController {
    func alert(text: String, haptic: SPAlertHaptic = .warning, completion: (() -> Void)? = nil) {
        SPAlert.present(message: text, haptic: haptic, completion: completion)
    }
}
