//
//  PassableUISwitch.swift
//  PGPro
//
//  Source: https://stackoverflow.com/a/46934347
//

import Foundation
import UIKit

public class PassableUISwitch: UISwitch {
    var params: [String: Any]

    override init(frame: CGRect) {
        self.params = [:]
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        self.params = [:]
        super.init(coder: aDecoder)
    }
}
