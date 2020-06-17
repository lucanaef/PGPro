//
//  FullTextFieldTableViewCell.swift
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

import UIKit

open class FullTextFieldTableViewCell: UITableViewCell {
    open var textField = TextField()

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
        self.textLabel?.isHidden = true
        self.contentView.viewWithTag(1)?.removeFromSuperview()
        self.contentView.viewWithTag(2)?.removeFromSuperview()
        self.contentView.viewWithTag(3)?.removeFromSuperview()
        self.contentView.addSubview(self.textField)
        self.textField.tag = 1
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.textAlignment = .left
        self.textField.pinEdges(to: contentView)
    }

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.textField.becomeFirstResponder()
    }
}

open class TextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}
