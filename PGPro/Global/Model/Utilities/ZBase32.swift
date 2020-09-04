//
//  ZBase32.swift
//  PGPro
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation


/**
    Utilities for handling ZBase-32 encoding.
    See: https://tools.ietf.org/html/rfc6189#section-5.1.6
 */
public class ZBase32 {

    private init() {}

    private static let alphabet = Array("ybndrfg8ejkmcpqxot1uwisza345h769")

    public static func encode(_ data: Data, appendPadding padded: Bool) -> String {
        var result = String()

        let remainderLength = data.count % 5
        let normalizedLength = data.count - remainderLength

        for i in stride(from: 0, to: normalizedLength, by: 5) {
            result.append(alphabet[((Int(data[i]) & 0xff) >> 3) & 0x1f])
            result.append(alphabet[(((Int(data[i]) & 0xff) << 2) | ((Int(data[i + 1]) & 0xff) >> 6)) & 0x1f])
            result.append(alphabet[((Int(data[i + 1]) & 0xff) >> 1) & 0x1f])
            result.append(alphabet[(((Int(data[i + 1]) & 0xff) << 4) | ((Int(data[i + 2]) & 0xff) >> 4)) & 0x1f])
            result.append(alphabet[(((Int(data[i + 2]) & 0xff) << 1) | ((Int(data[i + 3]) & 0xff) >> 7)) & 0x1f])
            result.append(alphabet[((Int(data[i + 3]) & 0xff) >> 2) & 0x1f])
            result.append(alphabet[(((Int(data[i + 3]) & 0xff) << 3) | ((Int(data[i + 4]) & 0xff) >> 5)) & 0x1f])
            result.append(alphabet[(Int(data[i + 4]) & 0xff) & 0x1f])
        }

        switch (remainderLength) {
        case 1:
            result.append(alphabet[((Int(data[normalizedLength]) & 0xff) >> 3) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength]) & 0xff) >> 2) & 0x1f])
            if (padded) { result.append("======") }
        case 2:
            result.append(alphabet[((Int(data[normalizedLength]) & 0xff) >> 3) & 0x1f])
            result.append(alphabet[(((Int(data[normalizedLength]) & 0xff) << 2) | ((Int(data[normalizedLength + 1]) & 0xff) >> 6)) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength + 1]) & 0xff) >> 1) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength + 1]) & 0xff) << 4) & 0x1f])
            if (padded) { result.append("====") }
        case 3:
            result.append(alphabet[((Int(data[normalizedLength]) & 0xff) >> 3) & 0x1f])
            result.append(alphabet[(((Int(data[normalizedLength]) & 0xff) << 2) | ((Int(data[normalizedLength + 1]) & 0xff) >> 6)) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength + 1]) & 0xff) >> 1) & 0x1f])
            result.append(alphabet[(((Int(data[normalizedLength + 1]) & 0xff) << 4) | ((Int(data[normalizedLength + 2]) & 0xff) >> 4)) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength + 2]) & 0xff) << 1) & 0x1f])
            if (padded) { result.append("===") }
        case 4:
            result.append(alphabet[((Int(data[normalizedLength]) & 0xff) >> 3) & 0x1f])
            result.append(alphabet[(((Int(data[normalizedLength]) & 0xff) << 2) | ((Int(data[normalizedLength + 1]) & 0xff) >> 6)) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength + 1]) & 0xff) >> 1) & 0x1f])
            result.append(alphabet[(((Int(data[normalizedLength + 1]) & 0xff) << 4) | ((Int(data[normalizedLength + 2]) & 0xff) >> 4)) & 0x1f])
            result.append(alphabet[(((Int(data[normalizedLength + 2]) & 0xff) << 1) | ((Int(data[normalizedLength + 3]) & 0xff) >> 7)) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength + 3]) & 0xff) >> 2) & 0x1f])
            result.append(alphabet[((Int(data[normalizedLength + 3]) & 0xff) << 3) & 0x1f])
            if (padded) { result.append("=") }
        default:
            break
        }

        return result
    }

}


extension Data {

    var zBase32Encoded: String {
        ZBase32.encode(self, appendPadding: false)
    }

}
