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
import SwiftTryCatch

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
        let optionMenu = UIAlertController(title: nil,
                                           message: nil,
                                           preferredStyle: .actionSheet)

        let generateKey = UIAlertAction(title: "Generate Key Pair", style: .default) { _ -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "goToGenerateKey", sender: nil)
        }
        optionMenu.addAction(generateKey)

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

        var numOfImportedKeys = 0
        numOfImportedKeys = ContactListService.importKeys(keys: readKeys)

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
