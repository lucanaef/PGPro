//
//  PGProTestsKeys.swift
//  PGProTests
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

class PGProTestsKeys {

    private init() {}

    private static let bundle = Bundle(identifier: "lu.naef.PGProTests")!

    struct TestKeyURL {
        var id: Int
        var passphrase: String? = nil
        var url: URL {
            return bundle.url(forResource: "\(id)", withExtension: "asc")!
        }
        var isSupported: Bool = true
    }

    static let keys: [TestKeyURL] = [
        /** User ID:    PGProWithoutEmail <>
         *  Key ID:     CD832F8D
         *  Key Alg.:   RSA; 4096 bit
         *  Note:       Key has no email address
         */
        TestKeyURL(id: 1),

        /** User ID:    PGPro 2 <2@test.pgpro.app>
         *  Key ID:     4972679B
         *  Key Alg.:   DSA and Elgamal; 3072 bit
         *  Note:       -
         */
        TestKeyURL(id: 2, passphrase: "2.test.pgpro.app"),

        /** User ID:    Daniel harrington <harrington0703@gmail.com>
         *  Key ID:     ?
         *  Key Alg.:   ?
         *  Note:       https://github.com/lucanaef/PGPro/issues/35
         */
        // TestKeyURL(id: 3), ¡ missing passphrase !

        /** User ID:    Foo Bar <foo@bar.com>
         *  Key ID:     4C8002FC
         *  Key Alg.:   RSA; 4096 bit
         *  Note:       private.gpg-key.txt from https://github.com/lucanaef/PGPro/issues/17
         *              Assertion failure in -[PGPSecretKeyPacket buildSecretKeyDataAndForceV4:], PGPSecretKeyPacket.m:356
         *              Require IV (NSInternalInconsistencyException)
         */
        TestKeyURL(id: 4, passphrase: "very secure passphrase!", isSupported: false),

        /** User ID:    Foo Bar <foo@bar.com>
         *  Key ID:     4C8002FC
         *  Key Alg.:   RSA; 4096 bit
         *  Note:       private.master.gpg-key.txt from https://github.com/lucanaef/PGPro/issues/17
         */
        TestKeyURL(id: 5, passphrase: "very secure passphrase!")


    ]

}
