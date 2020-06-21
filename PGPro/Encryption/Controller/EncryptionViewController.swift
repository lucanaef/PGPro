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
    private var selectionLabel = "Select Public Keys..."

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

        // Add table view to super view
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
    }

    @objc
    private func updateView() {
        var label = "Select Public Keys..."
        let count = encryptionContacts.count
        
        if (count == 1) {
            label = encryptionContacts[0].userID
        } else if (count > 0) {
            label = encryptionContacts[0].name
            
            let tail = encryptionContacts.dropFirst()
            for ctct in tail {
                label.append(", " + ctct.name)
            }
        }
        selectionLabel = label
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
            self.textView.text = ""
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

    @objc
    private func tapDone(sender: Any) {
        view.endEditing(true)
    }

    @objc
    private func resetSelection() {
        encryptionContacts = [Contact]()
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
            encryptedMessage = try CryptographyService.encrypt(message: text, for: encryptionContacts)
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

            if (Preferences.attachPublicKey) {
                // TODO: Add exported key of specified contact
            }

            present(mailComposeViewController, animated: true, completion: nil)
        } else {
            let activityVC = UIActivityViewController(activityItems: [encryptedMessage], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
}

extension EncryptionViewController: UITableViewDataSource, UITableViewDelegate {

    private var selectionRow: Int { return 0 }
    private var messageRow: Int { return 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell!
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        cell.selectionStyle = .none

        switch (indexPath.row) {
        case selectionRow:
            cell.textLabel?.text = selectionLabel
            cell.accessoryType = .disclosureIndicator
        case messageRow:
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
        case selectionRow:
            let keySelectionViewController = KeySelectionViewController()
            keySelectionViewController.set(toType: .publicKey)
            keySelectionViewController.delegate = self
            navigationController?.pushViewController(keySelectionViewController, animated: true)
        case messageRow:
            return
        default:
            Log.s("indexPath out of bounds!")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.row) {
        case selectionRow:
            return 44
        case messageRow:
            var height = self.view.frame.height
            height -= 44
            height -= (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0)
            height -= (self.navigationController?.navigationBar.frame.height ?? 0.0)
            height -= (self.tabBarController?.tabBar.frame.size.height ?? 0.0)
            return height
        default:
            Log.e("indexPath out of bounds!")
            return 0
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

    func update(selected: [Contact]) {
        self.encryptionContacts = selected
        self.updateView()
    }

}
