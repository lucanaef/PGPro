//
//  String+Email.swift
//  PGPro
//
//  Source: https://emailregex.com/
//

import Foundation

extension String {

    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }

}
