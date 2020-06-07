//
//  DecryptionTableViewController.swift
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

class DecryptionTableViewController: UITableViewController {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var passphraseTextField: UITextField!
    @IBOutlet weak private var textView: UITextView!
    
    private var decryptionContact: Contact?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetSelection),
                                               name: Constants.NotificationNames.contactListChange,
                                               object: nil
        )
        setupView()
    }

    func setMessageField(to message: String?) {
        textView.text = message
    }
    
    @objc
    private func updateView() {
        var label = "Select Private Key..."
        if let decryptionContact = decryptionContact {
            label = decryptionContact.userID
        }
        titleLabel.text = label
        tableView.reloadData()
    }

    private func setupView() {
        // Navigation Bar:
        self.navigationController?.navigationBar.prefersLargeTitles = true
        let decryptButton = UIBarButtonItem(
            image: UIImage(systemName: "envelope.open.fill")?.withTintColor(UIColor.label),
            style: .done,
            target: self,
            action: #selector(decrypt)
        )
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "trash")?.withTintColor(UIColor.label),
            style: .plain,
            target: self,
            action: #selector(clearView)
        )
        navigationItem.rightBarButtonItems = [decryptButton, clearButton]
        // Main Table View:
        titleLabel.text = "Select Private Key..."
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    }

    @objc
    private func resetSelection() {
        decryptionContact = nil
        updateView()
    }
    
    @objc
    private func decrypt() {
        guard let encryptedMessage = textView.text else { return }
        guard let decryptionContact = decryptionContact else {
            alert(text: "No Private Key Selected!")
            return
        }

        do {
            let decryptedMessage = try CryptographyService.decrypt(message: encryptedMessage,
                                                                   by: decryptionContact,
                                                                   withPassphrase: passphraseTextField.text)
            present(decryptedMessage)
        } catch let error {
            switch error {
            case CryptographyError.emptyMessage:
                alert(text: "Please enter message first!")
            case CryptographyError.invalidMessage:
                alert(text: "Message is invalid!")
            case CryptographyError.requiresPassphrase:
                alert(text: "Decryption requires passphrase!")
            case CryptographyError.wrongPassphrase:
                alert(text: "Wrong passphrase!")
            case CryptographyError.frameworkError(let frameworkError):
                alert(text: "Decryption failed!")
                Log.e("DecryptionTableViewController.decrypt(): \(frameworkError)")
            case CryptographyError.failedDecryption:
                alert(text: "Decryption failed!")
            default:
                alert(text: "Decryption failed!")
                Log.e("DecryptionTableViewController.decrypt(): \(error)")
            }
            return
        }
    }


    private func present(_ message: String) {
        let decryptedMessageViewController = DecryptedMessageViewController()
        decryptedMessageViewController.show(message)

        // Embed view in a new navigation controller as a
        //  workaround to https://forums.developer.apple.com/thread/121861
        let decryptedMessageNavigation = UINavigationController()
        decryptedMessageNavigation.setViewControllers([decryptedMessageViewController], animated: false)
        decryptedMessageNavigation.modalPresentationStyle = .automatic

        self.present(decryptedMessageNavigation, animated: true, completion: nil)
    }

    @objc
    private func clearView() {
        let dialogMessage = UIAlertController(title: "Delete this message",
                                              message: "",
                                              preferredStyle: .alert)

        // Create OK button with action handler
        let confirm = UIAlertAction(title: "Confirm", style: .destructive, handler: { (_) -> Void in
            self.decryptionContact = nil
            self.textView.text = ""
            self.updateView()
        })

        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in return }

        // Add Confirm and Cancel button to dialog message
        dialogMessage.addAction(confirm)
        dialogMessage.addAction(cancel)

        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) { // Private Key Selection
            let keySelectionViewController = KeySelectionViewController()
            keySelectionViewController.set(toType: .privateKey)
            keySelectionViewController.delegate = self
            navigationController?.pushViewController(keySelectionViewController, animated: true)
        } else if (indexPath.row == 2) { // Paste from Clipboard
            textView.text = UIPasteboard.general.string
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Hide passphrase field if not required
        let keyRequiresPassphrase = decryptionContact?.keyRequiresPassphrase ?? false
        if !keyRequiresPassphrase, indexPath.row == 1 {  return 0 }

        if (indexPath.row == 3) { // (Full-height) Message Row
            var height = self.view.frame.height
            if (!keyRequiresPassphrase) {
                height -= 88
            } else {
                height -= 132
            }
            height -= (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0)
            height -= (self.navigationController?.navigationBar.frame.height ?? 0.0)
            height -= (self.tabBarController?.tabBar.frame.size.height ?? 0.0)

            return height

        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
}


extension DecryptionTableViewController: KeySelectionDelegate {

    func update(selected: [Contact]) {
        if selected.isEmpty {
            decryptionContact = nil
        } else {
            decryptionContact = selected[0]
        }
        self.updateView()
    }

}
