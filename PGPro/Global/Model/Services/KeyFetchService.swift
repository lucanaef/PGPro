//
//  KeyFetchService2.swift
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
import ObjectivePGP

class KeyFetchService {
    
    private init() {}
    
    
    /**
        Synchronous (blocking) function which tries to find a key for a given email address on a keyserver

         - Parameters:
            - email: Email address

         - Returns: PGP Public Key, if successful, nil otherwise
    */
    static func requestKey(email: String) -> Key? {
        
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard encodedEmail != nil else { return nil }
        
        let urlString = "https://pgp.circl.lu/pks/lookup?search=" + encodedEmail! + "&op=get"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let contents = try String(contentsOf: url)
            
            if let range = contents.range(of: #"-----BEGIN PGP PUBLIC KEY BLOCK-----(.|\n)*-----END PGP PUBLIC KEY BLOCK-----"#,
                                          options: .regularExpression) {
                /* Key found */
                let asciikey = String(contents[range])
                guard let asciiKeyData = asciikey.data(using: .utf8) else { return nil }
                
                do {
                    let keys = try ObjectivePGP.readKeys(from: asciiKeyData)
                    guard (!keys.isEmpty) else { return nil }
                    return keys[0]
                    
                } catch {
                    return nil
                }
                
            } else {
                /* No key found */
                return nil
            }
            
        } catch {
            /* Not able to fetch URL contents */
            return nil
        }
    }
    
}
