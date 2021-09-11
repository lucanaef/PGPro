//
//  YubikeyTableViewCell.swift
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

class YubikeyTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        self.accessoryType = .disclosureIndicator
        self.selectionStyle = .none
        self.detailTextLabel?.textColor = .secondaryLabel

        self.textLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        self.textLabel?.text = "YubiKey"
        self.detailTextLabel?.text = "Tap to connect"

        self.imageView?.image = UIImage(named: "LASKey")
        let itemSize = CGSize.init(width: 16, height: 43)
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale);
        let imageRect = CGRect.init(origin: CGPoint.zero, size: itemSize)
        self.imageView?.image!.draw(in: imageRect)
        self.imageView?.image! = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
