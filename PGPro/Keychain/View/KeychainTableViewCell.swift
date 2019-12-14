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
    
    @IBOutlet weak private var cellTitle: UILabel!
    @IBOutlet weak private var cellSubtitle: UILabel!

    func setContact(contact: Contact) {
        cellTitle.text = contact.name
        cellSubtitle.text = contact.email
        
        let currentDate = Date()
        let keyExpirationDate = contact.key.expirationDate ?? currentDate
        
        var icon = UIImage(systemName: "lock.shield.fill")
        if (keyExpirationDate < currentDate) { // Key expired
            icon = UIImage(systemName: "shield.slash")
        }
        self.imageView?.image = icon
    }
}
