//
//  PublicKeySelectionTableViewController.swift
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

class PublicKeySelectionTableViewController: UITableViewController {
    
    @IBOutlet var keySelectionTableView: UITableView!
    
    let contactList = ContactListService.getPublicKeyContacts()
    static var selectedRows = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        keySelectionTableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = contactList[indexPath.row]
        let cell = keySelectionTableView.dequeueReusableCell(withIdentifier: "KeySelectionTableViewCell") as! KeySelectionTableViewCell
        
        if (PublicKeySelectionTableViewController.selectedRows.contains(indexPath.row)) {
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
        if (PublicKeySelectionTableViewController.selectedRows.contains(indexPath.row)) {
            PublicKeySelectionTableViewController.selectedRows.remove(at: PublicKeySelectionTableViewController.selectedRows.firstIndex(of: indexPath.row)!)
            EncryptionTableViewController.encryptionContacts.remove(at: EncryptionTableViewController.encryptionContacts.firstIndex(of: contactList[indexPath.row])!)
        } else {
            PublicKeySelectionTableViewController.selectedRows.append(indexPath.row)
            EncryptionTableViewController.encryptionContacts.append(contactList[indexPath.row])
        }
        
        keySelectionTableView.reloadData()
        
        // Notify observers about changed key selection
        NotificationCenter.default.post(name: Constants.NotificationNames.publicKeySelectionChange,
                                        object: nil)
    }

}
