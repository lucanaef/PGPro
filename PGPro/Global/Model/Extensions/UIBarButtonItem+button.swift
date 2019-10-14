//
//  UIBarButtonItem+button.swift
//  PGPro
//
//  Source: https://stackoverflow.com/a/53775828
//

import Foundation
import UIKit

extension UIBarButtonItem {
    static func button(image: UIImage, title: String, target: Any, action: Selector) -> UIBarButtonItem {
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.sizeToFit()
        return UIBarButtonItem(customView: button)
    }
}
