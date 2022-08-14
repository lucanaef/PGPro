//
//  MimeParsingService.swift
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
import MimeParser

class MimeParsingService {

    private static let parser = MimeParser()

    static func parse(_ string: String) -> String {
        do {
            let mime = try parser.parse(string)
            return try decodeContent(of: mime) ?? string
        } catch {
            return string
        }
    }

    private static func decodeContent(of mime: Mime) throws -> String? {
        switch mime.content {
        case .body:
            return try mime.decodedContentString()
        case .mixed(let mimes), .alternative(let mimes):
            var result = ""
            for encapsulatedMime in mimes {
                if encapsulatedMime.header.contentType?.type != "text" { continue }
                let decodedSubstring = try decodeContent(of: encapsulatedMime)
                if let decodedSubstring = decodedSubstring {
                    result.append(contentsOf: decodedSubstring)
                }
            }
            return (result != "") ? result : nil
        }
    }
}
