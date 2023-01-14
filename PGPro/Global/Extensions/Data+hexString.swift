//
//  Data+hexString.swift
//
//  Source: https://stackoverflow.com/a/46663290
//

import Foundation

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for byte in 0..<len {
            let leftHalf = hexString.index(hexString.startIndex, offsetBy: byte*2)
            let rightHalf = hexString.index(leftHalf, offsetBy: 2)
            let bytes = hexString[leftHalf..<rightHalf]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
