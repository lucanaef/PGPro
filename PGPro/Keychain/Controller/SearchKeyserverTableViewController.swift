//
//  SearchKeyserverTableViewController.swift
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

import Foundation
import UIKit
import ObjectivePGP

class SearchKeyserverTableViewController: UITableViewController {

    @IBOutlet private weak var searchBar: UISearchBar!

    var foundKeys = [Key]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    var selectedRows: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(addContactCancel(sender:))
            )
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(addContactDone(sender:))
        )
    }

    @objc
    func addContactDone(sender: UIBarButtonItem) {
        if (selectedRows.isEmpty) {
            alert(text: "No Keys Selected!")
            return
        } else {
            var selectedKeys: [Key] = []
            for row in selectedRows { selectedKeys.append(foundKeys[row]) }

            let numOfImportedKeys = ContactListService.importKeys(keys: selectedKeys)
            if (numOfImportedKeys == 0) {
                alert(text: "No new keys imported")
            } else if (numOfImportedKeys == 1) {
                alert(text: "1 new key imported")
            } else {
                alert(text: "\(numOfImportedKeys) new keys imported")
            }
        }
        dismiss(animated: true, completion: nil)
    }

    @objc
    func addContactCancel(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foundKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "KeyCell")
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle,  reuseIdentifier: "KeyCell")
        }

        let key = foundKeys[indexPath.row]

        var primaryUser: User?
        if (key.isSecret) {
            guard let privateKey = key.secretKey else { return cell! }
            primaryUser = privateKey.primaryUser
        } else {
            guard let publicKey = key.publicKey else { return cell! }
            primaryUser = publicKey.primaryUser
        }
        if let primaryUser = primaryUser {
            cell!.textLabel!.text = primaryUser.userID
            cell!.detailTextLabel!.text = key.keyID.longIdentifier.insertSeparator(" ", atEvery: 4)
        }

        if selectedRows.contains(indexPath.row) {
            cell!.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell!.accessoryType = UITableViewCell.AccessoryType.none
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedRows.contains(indexPath.row) {
            guard let firstOccurence = selectedRows.firstIndex(of: indexPath.row) else { return }
            selectedRows.remove(at: firstOccurence)
        } else {
            selectedRows.append(indexPath.row)
        }
        self.tableView.reloadData()
    }

}

extension SearchKeyserverTableViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        print("[SearchKeyserverTableViewController] Search Button clicked!")

        guard let searchBarText = searchBar.text else { return }
        guard searchBarText.isValidEmail() else {
            alert(text: "Invalid Email Address!")
            return
        }
        VerifyingKeyserverInterface.getByEmail(email: searchBarText) { result in
            switch result {
                case .failure(let error):
                    print("[SearchKeyserverTableViewController] \(error)")
                    switch error {
                        case .invalidFormat:
                            DispatchQueue.main.async {
                                self.alert(text: "Invalid Format")
                            }
                        case .invalidResponse:
                            DispatchQueue.main.async {
                                self.alert(text: "Failed to get valid response from keyserver!")
                            }
                        case .keyNotFound:
                            DispatchQueue.main.async {
                                self.alert(text: "No key found!")
                            }
                        case .keyNotSupported:
                            DispatchQueue.main.async {
                                self.alert(text: "Found non-supported key!")
                            }
                        case .noConnection:
                            DispatchQueue.main.async {
                                self.alert(text: "No Connection to Keyserver!")
                            }
                        case .rateLimiting:
                            DispatchQueue.main.async {
                                self.alert(text: "Error due to Rate Limiting")
                            }
                        case .serverDatabaseMaintenance:
                            DispatchQueue.main.async {
                                self.alert(text: "Keyserver is under Database Maintenanc")
                            }
                    }
                case .success(let keys):
                    print("[SearchKeyserverTableViewController] Found key!")
                    self.foundKeys = keys
            }
        }
    }

}
