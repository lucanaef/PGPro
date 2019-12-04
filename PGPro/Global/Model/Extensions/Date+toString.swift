//
//  Date+toString.swift
//  PGPro
//
//  Source: https://gist.github.com/kunikullaya/6474fc6537ed616b1c617646d263555d
//

import Foundation

extension Date {

    func toString(format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
