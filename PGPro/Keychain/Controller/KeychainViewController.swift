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
import MobileCoreServices

class KeychainViewController: UIViewController {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var contacts = [Contact]()
    var filteredContacts = [Contact]()

    lazy var keychainTableView: UITableView = {
        let tv = UITableView()

        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.dataSource = self
        tv.register(KeychainTableViewCell.self, forCellReuseIdentifier: "KeychainTableViewCell")

        return tv
    }()

    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true

        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search Contacts..."
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.delegate = self
        searchController.searchBar.keyboardType = .emailAddress
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no

        return searchController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contacts = ContactListService.getContacts()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadData),
                                               name: Constants.NotificationNames.contactListChange,
                                               object: nil
        )

        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Keychain"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(plus(sender:))
        )

        /// Add search bar to super view
        navigationItem.searchController = searchController

        /// Add table view to super view
        view.addSubview(keychainTableView)
        keychainTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        keychainTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        keychainTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        keychainTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    @objc
    func reloadData() {
        DispatchQueue.main.async {
            self.contacts = ContactListService.getContacts()
            self.keychainTableView.reloadData()
        }
    }

    @objc
    func plus(sender: UIBarButtonItem) {
        let optionMenu = UIAlertController(title: nil,
                                           message: nil,
                                           preferredStyle: .actionSheet)

        let generateKey = UIAlertAction(title: "Generate Key Pair", style: .default) { _ -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "goToGenerateKey", sender: nil)
        }
        optionMenu.addAction(generateKey)

        let searchKeyserver = UIAlertAction(title: "Search on Keyserver", style: .default) { _ -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "goToSearchKeyserver", sender: nil)
        }
        optionMenu.addAction(searchKeyserver)

        let importKeyFromFile = UIAlertAction(title: "Import Keys from File", style: .default) { _ -> Void in
            self.importKeysFilePicker()
            optionMenu.dismiss(animated: true, completion: nil)
        }
        optionMenu.addAction(importKeyFromFile)

        let addKeyFromClipboard = UIAlertAction(title: "Add Key from Clipboard", style: .default) { _ -> Void in
            self.addKeyFromClipboard()
            optionMenu.dismiss(animated: true, completion: nil)
        }
        optionMenu.addAction(addKeyFromClipboard)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
        }
        optionMenu.addAction(cancel)

        present(optionMenu, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showContactDetail") {
            if let destVC = segue.destination as? ContactDetailTableViewController {
                destVC.contact = sender as? Contact
            }
        }
    }

    func addKeyFromClipboard() {
        guard let clipboardString = UIPasteboard.general.string else {
            // Clipboard is empty
            alert(text: "Clipboard is Empty!")
            return
        }

        var readKeys: [Key] = []
        do {
            readKeys = try KeyConstructionService.fromString(keyString: clipboardString)
        } catch {
            alert(text: "No Key found in Clipboard!")
            return
        }

        let numOfImportedKeys = ContactListService.importKeys(keys: readKeys)

        if (numOfImportedKeys == 0) {
            alert(text: "No new keys imported")
        } else if (numOfImportedKeys == 1) {
            alert(text: "1 new key imported")
        } else {
            alert(text: "\(numOfImportedKeys) new keys imported")
        }


    }

    func importKeysFilePicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeData as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
    }

    func filterContactsforSearchText(searchText: String){
        filteredContacts = contacts.filter({ (contact: Contact) -> Bool in
            // return every contact if no search text speficied
            if (searchController.searchBar.text?.isEmpty ?? true) {
                return true
            }

            let matchesName = contact.name.lowercased().contains(searchText.lowercased())
            let matchesEmail = contact.email.lowercased().contains(searchText.lowercased())

            return (matchesName || matchesEmail)
        })

        // apply filter
        keychainTableView.reloadData()
    }

    func isFiltering() -> Bool {
        let searchBarNotEmpty = !(searchController.searchBar.text?.isEmpty ?? true)
        return (searchController.isActive && searchBarNotEmpty)
    }

}


extension KeychainViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var numOfImportedKeys = 0

        for selectedFileURL in urls {
            do {
                let readKeys = try KeyConstructionService.fromFile(fileURL: selectedFileURL)
                numOfImportedKeys = ContactListService.importKeys(keys: readKeys)
            } catch let error {
                print("Error info: \(error)")
                continue
            }
        }

        if (numOfImportedKeys == 0) {
            alert(text: "No new keys imported")
        } else if (numOfImportedKeys == 1) {
            alert(text: "1 new key imported")
        } else {
            alert(text: "\(numOfImportedKeys) new keys imported")
        }

    }

}

extension KeychainViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredContacts.count
        } else {
            return contacts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cntct = contacts[indexPath.row]
        if isFiltering() {
            cntct = filteredContacts[indexPath.row]
        }
        if let cell = keychainTableView.dequeueReusableCell(withIdentifier: "KeychainTableViewCell") as? KeychainTableViewCell {
            cell.setContact(contact: cntct)
            return cell
        } else {
            return UITableViewCell() // Dummy return value
        }
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            if isFiltering() {
                let cntct = filteredContacts[indexPath.row]

                filteredContacts.remove(at: indexPath.row)
                keychainTableView.deleteRows(at: [indexPath], with: .bottom)

                let index = ContactListService.getIndex(contact: cntct)
                ContactListService.removeContact(index: index)
                contacts = ContactListService.getContacts()
                
            } else {
                // Remove from storage and update local list
                ContactListService.removeContact(index: indexPath.row)
                contacts = ContactListService.getContacts()

                // Remove from view and update view
                keychainTableView.deleteRows(at: [indexPath], with: .bottom)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var cntct = contacts[indexPath.row]
        if isFiltering(){
            cntct = filteredContacts[indexPath.row]
        }
        performSegue(withIdentifier: "showContactDetail", sender: cntct)
    }
}

extension KeychainViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        filterContactsforSearchText(searchText: searchBar.text ?? "")
    }

}

extension KeychainViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        filterContactsforSearchText(searchText: searchController.searchBar.text ?? "")
    }

}
