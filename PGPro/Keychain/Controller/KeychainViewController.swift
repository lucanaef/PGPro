//
//  KeychainViewController.swift
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
import ObjectivePGP

class KeychainViewController: UIViewController {
    
    @IBOutlet weak var keychainTableView: UITableView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(plus(sender:))
        )
        
        self.keychainTableView.delegate = self
        self.keychainTableView.dataSource = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reloadData),
                                               name: Constants.NotificationNames.contactListChange,
                                               object: nil
        )
    }
    
    @objc
    func reloadData() {
        DispatchQueue.main.async {
            self.keychainTableView.reloadData()
        }
    }

    @objc
    func plus(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToAddContact", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showContactDetail") {
            if let destVC = segue.destination as? ContactDetailTableViewController {
                destVC.contact = sender as? Contact
            }
        }
    }
}

extension KeychainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ContactListService.numberOfContacts()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let c = ContactListService.getContact(index: indexPath.row)
        if let cell = keychainTableView.dequeueReusableCell(withIdentifier: "KeychainTableViewCell") as? KeychainTableViewCell {
            cell.setContact(contact: c)
            return cell
        } else {
            // Dummy return value
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // Remove from Storage
            ContactListService.removeContact(index: indexPath.row)
            // Remove from View
            keychainTableView.deleteRows(at: [indexPath], with: .bottom)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cntct = ContactListService.getContact(index: indexPath.row)
        performSegue(withIdentifier: "showContactDetail", sender: cntct)
    }
}
