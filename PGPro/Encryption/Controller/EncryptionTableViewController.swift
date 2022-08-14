//
//  EncryptionTableViewController.swift
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

    @IBOutlet weak var keySelectionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!

    private var encryptionContacts = [Contact]()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetSelection),
                                               name: Constants.NotificationNames.contactListChange,
                                               object: nil
        )
        setupView()
    }

    private func setupView() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))

        keySelectionLabel.text = "Select Public Keys..."

        textView.placeholder = "Type Message to Encrypt..."
        textView.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))

        navigationController?.navigationBar.prefersLargeTitles = true
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
        navigationItem.rightBarButtonItems = [clearButton, encryptButton]
    }

    @objc
    private func updateView() {
        var label = "Select Public Keys..."
        let count = encryptionContacts.count

        if count == 1 {
            label = encryptionContacts[0].userID
        } else if count > 0 {
            label = encryptionContacts[0].name

            let tail = encryptionContacts.dropFirst()
            for ctct in tail {
                label.append(", " + ctct.name)
            }
        }

        keySelectionLabel.text = label
    }

    @objc
    private func clearView() {
        let dialogMessage = UIAlertController(title: "Delete this message",
                                              message: "",
                                              preferredStyle: .alert)

        // Create OK button with action handler
        let confirm = UIAlertAction(title: "Confirm", style: .destructive, handler: { (_) -> Void in
            self.textView.text = ""
            self.resetSelection()
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
                Log.e("EncryptionTableViewController.encrypt(): \(frameworkError)")
            default:
                alert(text: "Encryption failed!")
                Log.e("EncryptionTableViewController.encrypt(): \(error)")
            }
            return
        }

        #warning("TODO: clean up code below, add setting to deactivate")
        if !MFMailComposeViewController.canSendMail() {
            let activityVC = UIActivityViewController(activityItems: [encryptedMessage], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        } else {
            let addresses = encryptionContacts.map { $0.email }
            // Present native mail integration
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self as MFMailComposeViewControllerDelegate
            mailComposeViewController.delegate = self as UINavigationControllerDelegate
            mailComposeViewController.setToRecipients(addresses)
            mailComposeViewController.setMessageBody(encryptedMessage, isHTML: false)
            present(mailComposeViewController, animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let keySelectionViewController = KeySelectionViewController()
            keySelectionViewController.set(toType: .publicKey)
            keySelectionViewController.delegate = self
            navigationController?.pushViewController(keySelectionViewController, animated: true)
        } else {
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 {
            /* Message Row*/
            var height = self.view.frame.height
            height -= 44 // Key Selection Row Height
            height -= (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0)
            height -= (self.navigationController?.navigationBar.frame.height ?? 0.0)
            height -= (self.tabBarController?.tabBar.frame.size.height ?? 0.0)
            return height
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
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
