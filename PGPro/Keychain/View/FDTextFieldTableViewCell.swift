//
//  FDTextFieldTableViewCell.swift
//  FDTextFieldTableViewCell
//
//  Created by William Entriken on 2/2/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import UIKit

// @IBDesignable
/// A UITableViewCell with a UITextField inside
open class FDTextFieldTableViewCell: UITableViewCell {
    open var textField = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override open func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    private func setup() {
        self.detailTextLabel?.isHidden = true
        self.contentView.viewWithTag(3)?.removeFromSuperview()
        self.textField.tag = 3
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.textField)
        self.contentView.addConstraint(NSLayoutConstraint(
            item: self.textField,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .leading,
            multiplier: 1,
            constant: 50
        ))
        self.contentView.addConstraint(NSLayoutConstraint(
            item: self.textField,
            attribute: .top,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .top,
            multiplier: 1,
            constant: 8
        ))
        self.contentView.addConstraint(NSLayoutConstraint(
            item: self.textField,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .bottom,
            multiplier: 1,
            constant: -8
        ))
        self.contentView.addConstraint(NSLayoutConstraint(
            item: self.textField,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 1,
            constant: -16
        ))
        self.textField.textAlignment = .right
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textField.becomeFirstResponder()
    }
}
