//
//  String+insertedSeparator.swift
//  PGPro
//
//  Source: https://stackoverflow.com/a/55593474
//

extension String {

    func insertSeparator(_ separatorString: String, atEvery dist: Int) -> String {
        guard 0 < dist else { return self }
        return self.enumerated().map({String($0.element) + (($0.offset != self.count - 1 && $0.offset % dist ==  dist - 1) ? "\(separatorString)" : "")}).joined()
    }

    mutating func insertedSeparator(_ separatorString: String, atEvery dist: Int) {
        self = insertSeparator(separatorString, atEvery: dist)
    }
}
