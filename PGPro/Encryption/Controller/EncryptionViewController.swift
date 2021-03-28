//
//  EncryptionViewController.swift
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
import MessageUI

class EncryptionViewController: UIViewController {

    private let cellIdentifier = "EncryptionTableViewCell"

    private var encryptionContacts = [Contact]()
    private var signatureContact: Contact?
    private var signatureKeyPassphrase: String?
    private var passphraseRequired: Bool {
        if let signatureContact = signatureContact {
            return signatureContact.key.isEncryptedWithPassword
        } else {
            return false
        }
    }

    private var encryptionKeysSelectionLabel = "Select Contacts..."
    private var signatureKeysSelectionLabel = "Add Signature..."

    lazy private var tableView: UITableView = {
        let tableView = UITableView()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))

        return tableView
    }()

    lazy private var textView: UITextView = {
        let textView = UITextView()

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))

        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(adjustForKeyboard),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetSelection),
                                               name: Constants.NotificationNames.contactListChange,
                                               object: nil
        )
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.placeholder = "Type Message to Encrypt..."
    }

    private func setupView() {
        self.tabBarItem.title = "Encryption"
        self.navigationItem.title = "Encrypt Message"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        let encryptButton = UIBarButtonItem(
            image: UIImage(systemName: "envelope.fill")?.withTintColor(UIColor.label),
            style: .done,
            target: self,
            action: #selector(encrypt)
        )
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "trash")?.withTintColor(UIColor.label),
            style: .plain,
            target: self,
            action: #selector(clearView)
        )
        navigationItem.rightBarButtonItems = [encryptButton, clearButton]
        navigationItem.largeTitleDisplayMode = .always

        // Add table view to super view
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
    }

    @objc
    private func updateView() {
        var encryptionLabel = "Select Contacts..."
        var signatureLabel = "Add Signature..."

        let encryptionCount = encryptionContacts.count
        
        if (encryptionCount == 1) {
            encryptionLabel = encryptionContacts[0].userID
        } else if (encryptionCount > 1) {
            encryptionLabel = encryptionContacts[0].name
            
            let tail = encryptionContacts.dropFirst()
            for ctct in tail {
                encryptionLabel.append(", " + ctct.name)
            }
        }
        encryptionKeysSelectionLabel = encryptionLabel

        if let signatureContact = signatureContact {
            signatureLabel = signatureContact.userID
        }
        signatureKeysSelectionLabel = signatureLabel

        tableView.reloadData()
    }

    @objc
    private func clearView() {
        let dialogMessage = UIAlertController(title: "Delete this message",
                                              message: "",
                                              preferredStyle: .alert)

        // Create OK button with action handler
        let confirm = UIAlertAction(title: "Confirm", style: .destructive, handler: { (_) -> Void in
            self.resetSelection()
            self.signatureKeyPassphrase = nil
            self.textView.text = ""
            self.textView.textViewDidChange(self.textView)
            self.tableView.reloadData()
        })

        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in
            return
        }

        // Add Confirm and Cancel button to dialog message
        dialogMessage.addAction(confirm)
        dialogMessage.addAction(cancel)

        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }

    /* Adjusts the height of the message text view to the keyboard height.
        Source: https://www.hackingwithswift.com/example-code/uikit/how-to-adjust-a-uiscrollview-to-fit-the-keyboard
    */
    @objc
    func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset = .zero
        } else {
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        textView.scrollIndicatorInsets = textView.contentInset

        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
    }

    @objc
    private func tapDone(sender: Any) {
        view.endEditing(true)
    }

    @objc
    private func resetSelection() {
        encryptionContacts = [Contact]()
        signatureContact = nil
        updateView()
    }
    
    @objc
    private func encrypt() {
        guard let text = textView.text else { return }
        guard !encryptionContacts.isEmpty else {
            alert(text: "Select Public Keys First!")
            return
        }

        var encryptedMessage: String
        do {
            if let signatureContact = signatureContact {
                // For each private key included in signatureContacts OR encryptionContacts, we need the passphrase.
                //  That's how the framework call works (no separation between encryption and signing)

                // Check that encryption contacts don't contain private keys
                let noPrivateKeys = encryptionContacts.filter { $0.key.isSecret }.isEmpty
                guard noPrivateKeys else {
                    alert(text: "PGPro does not support signing messages if the encryption contacts include private keys.")
                    return
                }

                // Check that there is a valid non-nil passphrase for the signing key
                if passphraseRequired {
                    guard let signatureKeyPassphrase = signatureKeyPassphrase else {
                        alert(text: "Signing requires the passphrase of the private Key!")
                        return
                    }
                    guard CryptographyService.passphraseIsCorrect(signatureKeyPassphrase, for: signatureContact.key) else {
                        alert(text: "Incorrect Passphrase!")
                        return
                    }
                }

                encryptedMessage = try CryptographyService.encrypt(message: text, for: encryptionContacts, by: [signatureContact], passphraseForContact: { Contact in
                    // A bit hacky but it works since we only allow signing with one key and no private keys in encryption contacts
                    if Contact == signatureContact {
                        return self.signatureKeyPassphrase
                    } else {
                        Log.s("Framework requested passphrase for non-signing key or non-encrypted key!")
                        return nil
                    }
                })
            } else {
                encryptedMessage = try CryptographyService.encrypt(message: text, for: encryptionContacts)
            }
        } catch {
            switch error {
            case CryptographyError.emptyMessage:
                alert(text: "Please enter message first!")
            case CryptographyError.invalidMessage:
                alert(text: "Message is invalid!")
            case CryptographyError.frameworkError(let frameworkError):
                alert(text: "Encryption failed!")
                Log.e(frameworkError)
            default:
                alert(text: "Encryption failed!")
                Log.e(error)
            }
            return
        }

        if (Constants.User.canSendMail && Preferences.mailIntegrationEnabled) {
            let addresses = encryptionContacts.map { $0.email }
            // Present native mail integration
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self as MFMailComposeViewControllerDelegate
            mailComposeViewController.delegate = self as UINavigationControllerDelegate

            mailComposeViewController.setToRecipients(addresses)
            mailComposeViewController.setMessageBody(encryptedMessage, isHTML: false)

            present(mailComposeViewController, animated: true, completion: nil)
        } else {
            let activityVC = UIActivityViewController(activityItems: [encryptedMessage], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
}

extension EncryptionViewController: UITableViewDataSource, UITableViewDelegate {

    enum EncryptionRows: Int, CaseIterable {
        case encryptionContacts = 0
        case signatureContact = 1
        case passphrase = 2
        case message = 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EncryptionRows.allCases.count
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        signatureKeyPassphrase = textField.text
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell!
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        cell.selectionStyle = .none

        switch (indexPath.row) {
        case EncryptionRows.encryptionContacts.rawValue:
            cell.textLabel?.text = encryptionKeysSelectionLabel
            cell.accessoryType = .disclosureIndicator
        case EncryptionRows.signatureContact.rawValue:
            cell.textLabel?.text = signatureKeysSelectionLabel
            cell.accessoryType = .disclosureIndicator
        case EncryptionRows.passphrase.rawValue:
            let passphraseCell = FullTextFieldTableViewCell(style: .value1, reuseIdentifier: "FDTextFieldTableViewCell")
            passphraseCell.textField.placeholder = "Passphrase"
            passphraseCell.textField.text = signatureKeyPassphrase
            passphraseCell.textField.clearButtonMode = .never
            passphraseCell.textField.textContentType = .password
            passphraseCell.textField.isSecureTextEntry = true
            passphraseCell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
            cell = passphraseCell
        case EncryptionRows.message.rawValue:
            let cellView = cell.contentView
            cellView.addSubview(textView)
            textView.pinEdges(to: cellView)
        default:
            Log.s("indexPath out of bounds!")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.row) {
        case EncryptionRows.encryptionContacts.rawValue:
            let encryptionContactSelectionVC = KeySelectionViewController()
            encryptionContactSelectionVC.set(toType: .publicKey)
            encryptionContactSelectionVC.delegate = self
            navigationController?.pushViewController(encryptionContactSelectionVC, animated: true)
        case EncryptionRows.signatureContact.rawValue:
            let signatureContactSelectionVC = KeySelectionViewController()
            signatureContactSelectionVC.set(toType: .privateKey)
            signatureContactSelectionVC.delegate = self
            navigationController?.pushViewController(signatureContactSelectionVC, animated: true)
        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.row) {
        case EncryptionRows.passphrase.rawValue:
            return passphraseRequired ? 44 : 0
        case EncryptionRows.message.rawValue:
            var height = self.view.frame.height
            height -= 2*44 // Key Selection Rows
            height -= passphraseRequired ? 44 : 0 // Passphrase Row
            height -= (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0)
            height -= (self.navigationController?.navigationBar.frame.height ?? 0.0)
            height -= (self.tabBarController?.tabBar.frame.size.height ?? 0.0)
            return height
        default:
            return 44
        }
    }

}

extension EncryptionViewController: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
    
}

extension EncryptionViewController: KeySelectionDelegate {

    func update(selected: [Contact], for type: Constants.KeyType) {
        if type == Constants.KeyType.publicKey {
            self.encryptionContacts = selected
        } else if type == Constants.KeyType.privateKey {
            self.signatureContact = selected[0]
        }

        self.updateView()
    }

}
