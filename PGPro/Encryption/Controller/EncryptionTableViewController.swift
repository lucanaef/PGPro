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
import ObjectivePGP

class EncryptionTableViewController: UITableViewController {
    
    @IBOutlet weak var keySelectionLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    static var encryptionContacts = [Contact]()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        self.hideKeyboardWhenTappedAround()
        
        update()
        textView.placeholder = "Enter Message to Encrypt..."
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "envelope.fill")?.withTintColor(UIColor.label),
            style: .plain,
            target: self,
            action: #selector(encrypt)
        )
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.update),
                                               name: Constants.NotificationNames.publicKeySelectionChange,
                                               object: nil
        )
    }

    @objc
    func update() {
        var label = "Select Public Keys..."
        let count = EncryptionTableViewController.encryptionContacts.count
        
        if (count == 1) {
            label = EncryptionTableViewController.encryptionContacts[0].userID
        } else if (count > 0) {
            label = EncryptionTableViewController.encryptionContacts[0].name
            
            let tail = EncryptionTableViewController.encryptionContacts.dropFirst()
            for ctct in tail {
                label.append(", " + ctct.name)
            }
        }
        
        keySelectionLabel.text = label
    }
    
    @objc
    func encrypt() {
        if let text = textView.text {
            if (textView.text == "") {
                alert(text: "Enter Message to Encrypt!")
                return
            }
            
            if (!EncryptionTableViewController.encryptionContacts.isEmpty) {
                do {
                    
                    var encryptionKeys = [Key]()
                    for cntct in EncryptionTableViewController.encryptionContacts {
                        encryptionKeys.append(cntct.key)
                    }
                    
                    let encryptedBin = try ObjectivePGP.encrypt(text.data(using: .utf8)!,
                                                                addSignature: false,
                                                                using: encryptionKeys)

                    
                    let armoredMsg = Armor.armored(encryptedBin, as: .message)
                    
                    
                    if !MFMailComposeViewController.canSendMail() {
                        let activityVC = UIActivityViewController(activityItems: [armoredMsg], applicationActivities: nil)
                        activityVC.popoverPresentationController?.sourceView = self.view
                        
                        self.present(activityVC, animated: true, completion: nil)
                        return
                    } else {
                        let mailComposeViewController = MFMailComposeViewController()
                        
                        var addresses: [String] = []
                        for cntct in EncryptionTableViewController.encryptionContacts {
                            addresses.append(cntct.email)
                        }
                        mailComposeViewController.mailComposeDelegate = self as MFMailComposeViewControllerDelegate
                        mailComposeViewController.delegate = self as UINavigationControllerDelegate
                        mailComposeViewController.setToRecipients(addresses)
                        mailComposeViewController.setMessageBody(armoredMsg, isHTML: false)
                    
                        present(mailComposeViewController, animated: true, completion: nil)
                    }

                    
                } catch {
                    alert(text: "Encryption Failed!")
                    return
                }
                
            } else {
                alert(text: "Select Public Keys First!")
                return
            }
            
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            performSegue(withIdentifier: "showPublicKeys", sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 1) {
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

extension EncryptionTableViewController: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
    
}
