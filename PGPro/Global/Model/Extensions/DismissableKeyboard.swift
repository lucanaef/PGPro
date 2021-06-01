//
//  DismissableKeyboard.swift
//  PGPro
//
//  Source: https://www.swiftdevcenter.com/uitextview-dismiss-keyboard-swift/
//  Modified by Luca Näf
//

import UIKit

protocol DismissableKeyboard {
    func addKeyboardDismissButton(target: Any, selector: Selector)
}

extension UITextView: DismissableKeyboard {
    func addKeyboardDismissButton(target: Any, selector: Selector) {
        /// Create a UIToolbar
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))
        /// Make the UIToolbar transparent (see https://stackoverflow.com/a/18969325)
        toolBar.setBackgroundImage(UIImage(),
                                   forToolbarPosition: .any,
                                   barMetrics: .default)
        toolBar.setShadowImage(UIImage(), forToolbarPosition: .any)
        /// Create a UIBarButtonItem of type flexibleSpace
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        /// Create UIBarButtonItem using parameter title, target and action
        let barButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .done, target: target, action: selector)
        barButton.tintColor = UIColor.label
        /// Assign this two UIBarButtonItem to toolBar
        toolBar.setItems([flexible, barButton], animated: false)
        /// Set this toolBar as inputAccessoryView to the UITextView/UIText
        self.inputAccessoryView = toolBar
    }
}

extension UITextField: DismissableKeyboard {
    func addKeyboardDismissButton(target: Any, selector: Selector) {
        /// Create a UIToolbar
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))
        /// Make the UIToolbar transparent (see https://stackoverflow.com/a/18969325)
        toolBar.setBackgroundImage(UIImage(),
                                   forToolbarPosition: .any,
                                   barMetrics: .default)
        toolBar.setShadowImage(UIImage(), forToolbarPosition: .any)
        /// Create a UIBarButtonItem of type flexibleSpace
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        /// Create UIBarButtonItem using parameter title, target and action
        let barButton = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .done, target: target, action: selector)
        barButton.tintColor = UIColor.label
        /// Assign this two UIBarButtonItem to toolBar
        toolBar.setItems([flexible, barButton], animated: false)
        /// Set this toolBar as inputAccessoryView to the UITextView/UIText
        self.inputAccessoryView = toolBar
    }
}
