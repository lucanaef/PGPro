//
//  KeychainTableViewCell.swift
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

class KeychainTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        self.accessoryType = .disclosureIndicator
        self.selectionStyle = .none
        self.detailTextLabel?.textColor = .secondaryLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContact(contact: Contact) {

        self.textLabel?.text = contact.name
        self.detailTextLabel?.text = contact.email

        var icon = UIImage(systemName: contact.keySymbol,
                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 27, weight: .light))
        let currentDate = Date(), keyExpirationDate = contact.key.expirationDate ?? currentDate
        if keyExpirationDate < currentDate { // Key expired
            icon = icon?.withTintColor(.red, renderingMode: .alwaysOriginal)
        }
        self.imageView?.image = icon
    }
}
