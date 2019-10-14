//
//  UIAlertController+TextField.swift
//  PGPro
//
//  Source: https://gist.github.com/ole/f76630731c9a0cda90bb6bae28e82927
//

import Foundation
import UIKit

/// A validation rule for text input.
public enum TextValidationRule {
    /// Any input is valid, including an empty string.
    case noRestriction
    /// The input must not be empty.
    case nonEmpty
    /// The enitre input must match a regular expression. A matching substring is not enough.
    case regularExpression(NSRegularExpression)
    /// The input is valid if the predicate function returns `true`.
    case predicate((String) -> Bool)
    
    public func isValid(_ input: String) -> Bool {
        switch self {
        case .noRestriction:
            return true
        case .nonEmpty:
            return !input.isEmpty
        case .regularExpression(let regex):
            let fullNSRange = NSRange(input.startIndex..., in: input)
            return regex.rangeOfFirstMatch(in: input, options: .anchored, range: fullNSRange) == fullNSRange
        case .predicate(let p):
            return p(input)
        }
    }
}

extension UIAlertController {
    public enum TextInputResult {
        /// The user tapped Cancel.
        case cancel
        /// The user tapped the OK button. The payload is the text they entered in the text field.
        case ok(String)
    }
    
    /// Creates a fully configured alert controller with one text field for text input, a Cancel and
    /// and an OK button.
    ///
    /// - Parameters:
    ///   - title: The title of the alert view.
    ///   - message: The message of the alert view.
    ///   - cancelButtonTitle: The title of the Cancel button.
    ///   - okButtonTitle: The title of the OK button.
    ///   - validationRule: The OK button will be disabled as long as the entered text doesn't pass
    ///     the validation. The default value is `.noRestriction` (any input is valid, including
    ///     an empty string).
    ///   - textFieldConfiguration: Use this to configure the text field (e.g. set placeholder text).
    ///   - onCompletion: Called when the user closes the alert view. The argument tells you whether
    ///     the user tapped the Close or the OK button (in which case this delivers the entered text).
    public convenience init(title: String, message: String? = nil,
                            cancelButtonTitle: String, okButtonTitle: String,
                            validate validationRule: TextValidationRule = .noRestriction,
                            textFieldConfiguration: ((UITextField) -> Void)? = nil,
                            onCompletion: @escaping (TextInputResult) -> Void) {
        self.init(title: title, message: message, preferredStyle: .alert)
        
        /// Observes a UITextField for various events and reports them via callbacks.
        /// Sets itself as the text field's delegate and target-action target.
        class TextFieldObserver: NSObject, UITextFieldDelegate {
            let textFieldValueChanged: (UITextField) -> Void
            let textFieldShouldReturn: (UITextField) -> Bool
            
            init(textField: UITextField, valueChanged: @escaping (UITextField) -> Void, shouldReturn: @escaping (UITextField) -> Bool) {
                self.textFieldValueChanged = valueChanged
                self.textFieldShouldReturn = shouldReturn
                super.init()
                textField.delegate = self
                textField.addTarget(self, action: #selector(TextFieldObserver.textFieldValueChanged(sender:)), for: .editingChanged)
            }
            
            @objc func textFieldValueChanged(sender: UITextField) {
                textFieldValueChanged(sender)
            }
            
            // MARK: UITextFieldDelegate
            func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                return textFieldShouldReturn(textField)
            }
        }
        
        var textFieldObserver: TextFieldObserver?
        
        // Every `UIAlertAction` handler must eventually call this
        func finish(result: TextInputResult) {
            // Capture the observer to keep it alive while the alert is on screen
            textFieldObserver = nil
            onCompletion(result)
        }
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: { _ in
            finish(result: .cancel)
        })
        let okAction = UIAlertAction(title: okButtonTitle, style: .default, handler: { [unowned self] _ in
            finish(result: .ok(self.textFields?.first?.text ?? ""))
        })
        addAction(cancelAction)
        addAction(okAction)
        preferredAction = okAction
        
        addTextField(configurationHandler: { textField in
            textFieldConfiguration?(textField)
            textFieldObserver = TextFieldObserver(textField: textField,
                                                  valueChanged: { textField in
                                                    okAction.isEnabled = validationRule.isValid(textField.text ?? "")
            },
                                                  shouldReturn: { textField in
                                                    validationRule.isValid(textField.text ?? "")
            })
        })
        // Start with a disabled OK button if necessary
        okAction.isEnabled = validationRule.isValid(textFields?.first?.text ?? "")
    }
}
