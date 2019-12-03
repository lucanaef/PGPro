//
//  AddContactTableViewController.swift
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
import SafariServices
import ObjectivePGP

class AddContactTableViewController: UITableViewController {
    
    @IBOutlet private var addContactTableView: UITableView!
    
    @IBOutlet private weak var inputName: UITextField!
    @IBOutlet private weak var inputEmail: UITextField!
    
    @IBAction private func lookupButtonTapped(_ sender: UIButton) {
        if let name = inputName.text {
            if let email = inputEmail.text {
                
                if !validateInput() {
                    return
                }
                
                if ContactListService.addContactFromKeyserver(name: name, email: email) {
                    dismiss(animated: true, completion: nil)
                } else {
                    alert(text: "Failed to Retrieve Key from Keyserver!")
                }
            }
        }
    }
    
    
    @IBOutlet weak private var publicKeySwitch: UISwitch!
    @IBAction private func publicKeyToggleAction(_ sender: Any) {
        addContactTableView.reloadData()
    }
    
    @IBOutlet weak private var publicKeyTextView: UITextView!
    
    @IBOutlet weak private var privateKeySwitch: UISwitch!
    @IBAction private func privateKeyToggleAction(_ sender: Any) {
        addContactTableView.reloadData()
    }
    
    @IBOutlet weak private var privateKeyTextView: UITextView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(addContactCancel(sender:))
        )
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(addContactDone(sender:))
        )
        
        publicKeyTextView.placeholder = "Enter Public Key..."
        privateKeyTextView.placeholder = "Enter Private Key..."
        
        self.hideKeyboardWhenTappedAround()
        
    }
    
    func validateInput() -> Bool {
        
        guard let name = inputName.text else { return false }
        guard let email = inputEmail.text else { return false }
        
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
    func addContactDone(sender: UIBarButtonItem) {
        if validateInput() {
            
            var publicKey = Key(secretKey: nil, publicKey: nil).publicKey
            var privateKey = Key(secretKey: nil, publicKey: nil).secretKey
            
            if (publicKeySwitch.isOn) {
                guard let asciiKeyData = publicKeyTextView.text.data(using: .utf8) else { return }
                do {
                    let readKeys = try ObjectivePGP.readKeys(from: asciiKeyData)
                    if (readKeys.isEmpty) {
                        alert(text: "Public Key Import Failed!")
                        return
                    } else {
                        publicKey = readKeys[0].publicKey
                    }
                } catch {
                    alert(text: "Public Key Import Failed!")
                    return
                }
            }

            if (privateKeySwitch.isOn) {
                guard let asciiKeyData = privateKeyTextView.text.data(using: .utf8) else { return }
                do {
                    let readKeys = try ObjectivePGP.readKeys(from: asciiKeyData)
                    if (readKeys.isEmpty) {
                        alert(text: "Private Key Import Failed!")
                        return
                    } else {
                        privateKey = readKeys[0].secretKey
                    }
                } catch {
                    alert(text: "Private Key Import Failed!")
                    return
                }
            }
            
            let key = Key(secretKey: privateKey, publicKey: publicKey)

            guard let name = inputName.text else { return }
            guard let email = inputEmail.text else { return }
            
            if !ContactListService.addContact(name: name, email: email, key: key) {
                alert(text: "Contact with this Email Address Already Exists!")
            } else {
                dismiss(animated: true, completion: nil)
            }
            
        }
    }
    
    @objc
    func addContactCancel(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            var count = 3
            if privateKeySwitch.isOn {
                count += 1
            }
            return count
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 2 && indexPath.row == 1 && !publicKeySwitch.isOn) {
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
}
