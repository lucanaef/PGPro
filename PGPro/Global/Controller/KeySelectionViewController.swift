//
//  KeySelectionView.swift
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

protocol KeySelectionDelegate {
    func update(selected: [Contact], for type: Constants.KeyType)
}

class KeySelectionViewController: UIViewController {

    private var type: Constants.KeyType = .none {
        didSet {
            contacts = ContactListService.get(ofType: type)
        }
    }
    private var contacts = [Contact]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    private var selectedContacts = [Contact]()

    var delegate: KeySelectionDelegate?

    private lazy var tableView: UITableView = {
        let tableView = UITableView()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(KeySelectionTableViewCell.self, forCellReuseIdentifier: "KeySelectionTableViewCell")

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reset),
                                               name: Constants.NotificationNames.contactListChange,
                                               object: nil
        )

        // Setup Navigation Bar
        self.navigationController?.navigationBar.prefersLargeTitles = true

        // Add table view to super view
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        if (delegate != nil) { delegate?.update(selected: selectedContacts, for: type) }
    }

    func set(toType type: Constants.KeyType) {
        self.type = type

        switch type {
        case .publicKey:
            self.title = "Select Public Keys"
        case .privateKey:
            self.title = "Select Private Key"
        default:
            self.title = "Select Contacts"
        }
    }

    @objc
    private func reset() {
        self.contacts = ContactListService.get(ofType: self.type)
        self.selectedContacts = [Contact]()
        self.tableView.reloadData()
    }

    private func select(_ contact: Contact) {
        switch type {
        case .publicKey, .both:
            if isSelected(contact) {
                selectedContacts.remove(at: selectedContacts.firstIndex(of: contact)!)
            } else {
                selectedContacts.append(contact)
            }
            self.tableView.reloadData()
        case .privateKey:
            selectedContacts = [contact]
            self.tableView.reloadData()
            // auto-dismiss selection view
            _ = self.navigationController?.popViewController(animated: true)
        case .none:
            break
        }
    }

    private func isSelected(_ contact: Contact) -> Bool {
        selectedContacts.contains(contact)
    }

}

extension KeySelectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = contacts[indexPath.row]

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "KeySelectionTableViewCell") as? KeySelectionTableViewCell
        else {
            Log.e("Unable to deque reusable cell")
            return UITableViewCell()
        }

        cell.set(contact)
        if isSelected(contact) {
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(contacts[indexPath.row])
    }

}


