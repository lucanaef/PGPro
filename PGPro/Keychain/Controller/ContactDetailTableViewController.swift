//
//  ContactDetailTableViewController.swift
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

class ContactDetailTableViewController: UITableViewController {
    
    @IBOutlet weak private var name: UITextField!
    @IBAction private func nameEditingChanged(_ sender: Any) {
        addSaveButton()
    }
    @IBOutlet weak private var email: UITextField!
    @IBAction private func emailValueChanged(_ sender: Any) {
        addSaveButton()
    }
    
    @IBOutlet weak private var keyid: UILabel!
    @IBOutlet weak private var type: UILabel!
    @IBOutlet weak private var expires: UILabel!
    @IBOutlet weak private var fingerprint: UILabel!

    var saveButtonAdded = false
    
    var contact: Contact?
    var noKey = true

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = contact?.name
        setLabel()
    }
    
    func addSaveButton() {
        if !saveButtonAdded {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                                     target: self,
                                                                     action: #selector(saveChangedContact)
            )
            saveButtonAdded = true
        }
    }
    
    func validateInput() -> Bool {
        
        guard let name = name.text else { return false }
        guard let email = email.text else { return false }
        
        guard (name != "") else {
            alert(text: "Name Can't Be Empty!")
            return false
        }
        
        guard (email != "") else {
            alert(text: "Email Address Can't Be Empty!")
            return false
        }
        
        guard email.isValidEmail() else {
            alert(text: "Email Address Not Valid!")
            return false
        }
        
        return true
    }
    
    @objc
    func saveChangedContact () {
        if validateInput() {
            if let contact = contact {
                let newName = name.text ?? ""
                let newEmail = email.text ?? ""
                
                if !ContactListService.editContact(contact: contact, newName: newName, newEmail: newEmail) {
                    alert(text: "Contact with this Email Address Already Exists!")
                }
            }
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func setLabel() {
        guard let contact = contact else { return }
        
        name.text = contact.name
        email.text = contact.email
        
        let key = contact.key
        
        keyid.text = key.keyID.shortIdentifier.insertSeparator(" ", atEvery: 4)
        
        type.text = "None"
        if (key.isPublic && key.isSecret) {
            type.text = "Public & Private"
            noKey = false
        } else if (key.isPublic) {
            type.text = "Public"
            noKey = false
        } else if (key.isSecret) {
            type.text = "Private"
            noKey = false
        }
        
        expires.text = "Never"
        if let expirationDate = key.expirationDate {
            expires.text = expirationDate.toString()
        }
        
        fingerprint.text = ""
        if let pubKey = key.publicKey {
            fingerprint.text = pubKey.fingerprint.description().insertSeparator(" ", atEvery: 4)
        }
        if let secKey = key.secretKey {
            fingerprint.text = secKey.fingerprint.description().insertSeparator(" ", atEvery: 4)
        }
    }

    func setShare() {
        guard let contact = contact else { return }
        
        var activityItem = ""
        do {
            activityItem = try Armor.armored(contact.key.export(), as: .publicKey)
        } catch { }
        
        if (contact.key.isSecret) {
            let optionMenu = UIAlertController(title: nil,
                                               message: "Select Key to Share",
                                               preferredStyle: .actionSheet)
            
            let sharePublicKey = UIAlertAction(title: "Public Key", style: .default) { _ -> Void in
                optionMenu.dismiss(animated: true, completion: nil)
                self.share(activityItems: [activityItem])
            }
            optionMenu.addAction(sharePublicKey)
            
            let sharePrivateKey = UIAlertAction(title: "Private Key", style: .destructive) { _ -> Void in
                do {
                    activityItem = try Armor.armored(contact.key.export(), as: .secretKey)
                } catch { }
                optionMenu.dismiss(animated: true, completion: nil)
                self.share(activityItems: [activityItem])
            }
            optionMenu.addAction(sharePrivateKey)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
                optionMenu.dismiss(animated: true, completion: nil)
                return
            }
            optionMenu.addAction(cancelAction)
            
            present(optionMenu, animated: true, completion: nil)
        } else {
            self.share(activityItems: [activityItem])
        }
    
    }

    func share(activityItems: [Any]) {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        
        present(activityVC, animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if (noKey) {
            return super.numberOfSections(in: tableView) - 1
        } else {
            return super.numberOfSections(in: tableView)
        }
    }

    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView,
                            canPerformAction action: Selector,
                            forRowAt indexPath: IndexPath,
                            withSender sender: Any?) -> Bool {
        if (indexPath.section == 2) {
            return false
        } else if (action == #selector(UIResponderStandardEditActions.copy(_:))) {
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView,
                            performAction action: Selector,
                            forRowAt indexPath: IndexPath,
                            withSender sender: Any?) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIPasteboard.general.string = cell.detailTextLabel?.text
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 2) {
            setShare()
        }
    }
}
