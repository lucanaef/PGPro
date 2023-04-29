//
//  String+InsecureHashing.swift
//
//  Source: https://gist.github.com/shnhrrsn/c55f1e686b4bdf0d78d62b456fc2a3a1
//

import CryptoKit
import Foundation

private protocol ByteCountable {
  static var byteCount: Int { get }
}

extension Insecure.MD5: ByteCountable { }
extension Insecure.SHA1: ByteCountable { }

public extension String {
  func MD5(using encoding: String.Encoding = .utf8) -> String? {
    return self.hash(algo: Insecure.MD5.self, using: encoding)
  }

  func SHA1(using encoding: String.Encoding = .utf8) -> String? {
    return self.hash(algo: Insecure.SHA1.self, using: encoding)
  }

  private func hash<Hash: HashFunction & ByteCountable>(algo: Hash.Type, using encoding: String.Encoding = .utf8) -> String? {
    guard let data = self.data(using: encoding) else {
      return nil
    }

    return algo.hash(data: data).prefix(algo.byteCount).map {
      String(format: "%02hhx", $0)
    }.joined()
  }
}
