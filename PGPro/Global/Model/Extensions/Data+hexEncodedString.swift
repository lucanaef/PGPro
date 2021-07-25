//
//  Data+hexEncodedString.swift
//  PGPro
//
//  Source: http://stackoverflow.com/a/40089462
//

import Foundation

extension Data {
    var hexEncodedString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
