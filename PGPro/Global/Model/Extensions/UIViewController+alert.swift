//
//  UIViewController+alert.swift
//  PGPro
//

import Foundation
import UIKit

extension UIViewController {
    func alert(text: String) {
        let alertController = UIAlertController(title: text, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
}
