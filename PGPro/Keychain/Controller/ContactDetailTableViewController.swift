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
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var email: UILabel!
    
    @IBOutlet weak var id: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var expires: UILabel!
    @IBOutlet weak var fingerprint: UILabel!


    var contact: Contact?
    var noKey = true


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = contact?.name
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(setShare(sender:))
        )
        
        self.name.text = contact?.name
        self.email.text = contact?.email
        
        if let key = contact?.key {
            self.id.text = key.keyID.shortIdentifier.insertSeparator(" ", atEvery: 4)
            
            self.type.text = "None"
            if (key.isPublic && key.isSecret) {
                self.type.text = "Public & Private"
                noKey = false
            } else if (key.isPublic) {
                self.type.text = "Public"
                noKey = false
            } else if (key.isSecret) {
                self.type.text = "Private"
                noKey = false
            }
            
            self.expires.text = "Never"
            if let expirationDate = key.expirationDate {
                self.expires.text = expirationDate.toString()
            }
            
            self.fingerprint.text = ""
            if let fp = key.publicKey {
                self.fingerprint.text = fp.fingerprint.description().insertSeparator(" ", atEvery: 4)
            }
            if let fp = key.secretKey {
                self.fingerprint.text = fp.fingerprint.description().insertSeparator(" ", atEvery: 4)
            }
            
        }
        
    }


    @objc
    func setShare(sender: UIBarButtonItem) {
        if (contact!.key.isSecret) {
            var activityItem = try! Armor.armored(contact!.key.export(), as: .publicKey)
            
            let optionMenu = UIAlertController(title: nil,
                                               message: "Select Key to Share",
                                               preferredStyle: .actionSheet)
            
            let sharePublicKey = UIAlertAction(title: "Public Key", style: .default) { action -> Void in
                optionMenu.dismiss(animated: true, completion: nil)
                self.share(activityItems: [activityItem])
            }
            optionMenu.addAction(sharePublicKey)
            
            let sharePrivateKey = UIAlertAction(title: "Private Key", style: .destructive) { action -> Void in
                activityItem = try! Armor.armored(self.contact!.key.export(), as: .secretKey)
                optionMenu.dismiss(animated: true, completion: nil)
                self.share(activityItems: [activityItem])
            }
            optionMenu.addAction(sharePrivateKey)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                optionMenu.dismiss(animated: true, completion: nil)
                return
            }
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: nil)
        } else if (contact!.key.isPublic) {
            let activityItem = try! Armor.armored(contact!.key.export(), as: .publicKey)
            self.share(activityItems: [activityItem])
        }
    
    }


    func share(activityItems: [Any]) {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        
        self.present(activityVC, animated: true, completion: nil)
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        if (noKey) {
            return 1
        } else {
            return super.numberOfSections(in: tableView)
        }
    }


    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if (action == #selector(UIResponderStandardEditActions.copy(_:))) {
            return true
        }
        return false
    }


    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        let cell = tableView.cellForRow(at: indexPath)
        UIPasteboard.general.string = cell!.detailTextLabel?.text
    }

}
