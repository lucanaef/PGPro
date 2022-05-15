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
import MobileCoreServices
import ObjectivePGP
import EmptyDataSet_Swift

class KeychainViewController: UIViewController {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private var contacts = [Contact]()
    private var filteredContacts = [Contact]()

    lazy var keychainTableView: UITableView = {
        let tableView = UITableView()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(KeychainTableViewCell.self, forCellReuseIdentifier: "KeychainTableViewCell")

        tableView.emptyDataSetView { view in
            let keySymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .medium)
            let keySymbol = UIImage(systemName: "key", withConfiguration: keySymbolConfiguration)

            view.titleLabelString(NSAttributedString(string: "Keychain is Empty"))
                .detailLabelString(NSAttributedString(string: "Tap the '+' to add keys"))
                .image(keySymbol?.withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal))
        }

        return tableView
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

        contacts = ContactListService.get(ofType: .both)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadData),
                                               name: Constants.NotificationNames.contactListChange,
                                               object: nil
        )

        self.title = "Keychain"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(plus(sender:))
        )

        // Add search bar to super view
        navigationItem.searchController = searchController

        // Add table view to super view
        view.addSubview(keychainTableView)
        keychainTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        keychainTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        keychainTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        keychainTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    @objc
    func reloadData() {
        DispatchQueue.main.async {
            self.contacts = ContactListService.get(ofType: .both)
            self.keychainTableView.reloadData()
        }
    }

    @objc
    func plus(sender: UIBarButtonItem) {
        let optionMenu = UIAlertController(title: nil,
                                           message: nil,
                                           preferredStyle: .actionSheet)
        optionMenu.popoverPresentationController?.barButtonItem = sender

        let generateKey = UIAlertAction(title: "Generate Key Pair", style: .default) { _ -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
            let generateKeyViewController = GenerateKeyViewController()
            let navController = UINavigationController(rootViewController: generateKeyViewController)
            self.present(navController, animated: true)
        }
        optionMenu.addAction(generateKey)

        let searchKeyserver = UIAlertAction(title: "Search on Keyserver", style: .default) { _ -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
            let searchKeyserverViewController = SearchKeyserverViewController()
            let navController = UINavigationController(rootViewController: searchKeyserverViewController)
            self.present(navController, animated: true)
        }
        optionMenu.addAction(searchKeyserver)

        let importKeyFromFile = UIAlertAction(title: "Import Keys from File", style: .default) { _ -> Void in
            self.importKeysFilePicker()
            optionMenu.dismiss(animated: true)
        }
        optionMenu.addAction(importKeyFromFile)

        let addKeyFromClipboard = UIAlertAction(title: "Add Key from Clipboard", style: .default) { _ -> Void in
            self.addKeyFromClipboard()
            optionMenu.dismiss(animated: true)
        }
        optionMenu.addAction(addKeyFromClipboard)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            optionMenu.dismiss(animated: true)
        }
        optionMenu.addAction(cancel)

        present(optionMenu, animated: true)
    }

    private func addKeyFromClipboard() {
        guard let clipboardString = UIPasteboard.general.string else {
            alert(text: "Clipboard is Empty!")
            return
        }

        var readKeys = [Key]()
        do {
            readKeys = try KeyConstructionService.fromString(keyString: clipboardString)
        } catch let error {
            var message: String
            switch error {
            case KeyConstructionService.KeyConstructionError.invalidFormat:
                message = "Clipboard contains invalid key!"
            case KeyConstructionService.KeyConstructionError.keyNotSupported:
                message = "Clipboard contains unsupported key!"
            default:
                message = "No valid Key found in Clipboard!"
            }
            alert(text: message)
            return
        }

        let result: ContactListResult = ContactListService.importFrom(readKeys)
        alert(result)
    }

    private func importKeysFilePicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeData as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
    }

    private func filterContactsforSearchText(searchText: String) {
        filteredContacts = contacts.filter({ (contact: Contact) -> Bool in
            // return every contact if no search text speficied
            if searchController.searchBar.text?.isEmpty ?? true {
                return true
            }

            let matchesName = contact.name.lowercased().contains(searchText.lowercased())
            let matchesEmail = contact.email.lowercased().contains(searchText.lowercased())

            return (matchesName || matchesEmail)
        })
        keychainTableView.reloadData() // apply filter
    }

    private func isFiltering() -> Bool {
        let searchBarNotEmpty = !(searchController.searchBar.text?.isEmpty ?? true)
        return (searchController.isActive && searchBarNotEmpty)
    }

}

// MARK: - Document Picker

extension KeychainViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        var importResult = ContactListResult(successful: 0, unsupported: 0, duplicates: 0)

        for selectedFileURL in urls {
            do {
                let readKeys = try KeyConstructionService.fromFile(fileURL: selectedFileURL)

                if readKeys.isEmpty {
                    importResult.unsupported += 1
                    continue
                }

                let results = ContactListService.importFrom(readKeys)
                importResult.successful += results.successful
                importResult.unsupported += results.unsupported
                importResult.duplicates += results.duplicates
            } catch let error {
                Log.e("Error info: \(error)")
                continue
            }
        }

        alert(importResult)
    }

}

// MARK: - Table View

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

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if isFiltering() {
                let cntct = filteredContacts[indexPath.row]

                filteredContacts.remove(at: indexPath.row)
                keychainTableView.deleteRows(at: [indexPath], with: .bottom)

                ContactListService.remove(cntct)
                contacts = ContactListService.get(ofType: .both)

            } else {
                // Remove from storage and update local list
                ContactListService.remove(contacts[indexPath.row])
                contacts = ContactListService.get(ofType: .both)

                // Remove from view and update view
                keychainTableView.deleteRows(at: [indexPath], with: .bottom)
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var contact = contacts[indexPath.row]
        if isFiltering() {
            contact = filteredContacts[indexPath.row]
        }

        let detailViewController = ContactDetailViewController()
        let contactDetails = ContactDetails(for: contact)
        detailViewController.setModel(to: contactDetails)
        self.navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - Search Bar

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
