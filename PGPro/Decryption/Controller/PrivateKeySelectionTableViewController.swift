//
//  PrivateKeySelectionTableViewController.swift
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

class PrivateKeySelectionTableViewController: UITableViewController {

    @IBOutlet var keySelectionTableView: UITableView!
    
    let contactList = ContactListService.getPrivateKeyContacts()
    static var selectedRow = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        keySelectionTableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = contactList[indexPath.row]
        let cell = keySelectionTableView.dequeueReusableCell(withIdentifier: "KeySelectionTableViewCell") as! KeySelectionTableViewCell
        
        if (indexPath.row == PrivateKeySelectionTableViewController.selectedRow) {
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        
        cell.setContact(contact: c)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactList.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PrivateKeySelectionTableViewController.selectedRow = indexPath.row
        DecryptionTableViewController.decryptionContact = contactList[indexPath.row]
        keySelectionTableView.reloadData()
        
        // Notify observers about changed key selection
        NotificationCenter.default.post(name: Constants.NotificationNames.privateKeySelectionChange,
                                        object: nil)
    }
    
}
