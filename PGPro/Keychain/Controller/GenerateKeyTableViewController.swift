//
//  GenerateKeyTableViewController.swift
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

class GenerateKeyTableViewController: UITableViewController {
    
    @IBOutlet weak private var name: UITextField!
    @IBOutlet weak private var email: UITextField!
    @IBAction func passphraseValueChanged(_ sender: Any) {
        updateStrengthIndicator()
    }
    @IBAction func passphraseChanged(_ sender: Any) {
        updateStrengthIndicator()
    }
    @IBOutlet weak private var passphrase: UITextField!
    @IBOutlet weak private var passphraseConfirmation: UITextField!
    @IBOutlet weak private var strengthIndicator: UIProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()

        strengthIndicator.setProgress(0, animated:  false)

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
    }
    
    @objc
    func addContactDone(sender: UIBarButtonItem) {
        
        // Validate Input
        if validateInput() {
            guard let name = name.text else { return }
            guard let email = email.text else { return }
            let userID = name + " <" + email + ">"
            
            // Generate Key
            let keyGen = KeyGenerator()
            let key = keyGen.generate(for: userID, passphrase: passphrase.text)
            
            // Create Contact
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

    func updateStrengthIndicator() {

        let currentPassphrase = passphrase.text ?? ""
        let passphraseEntropy = Navajo.entropy(of: currentPassphrase)
        // Normalized estimated passphrase strength value
        let strengthVal = min(128.0, passphraseEntropy) / 128.0
        let strength = Navajo.passwordStrength(forEntropy: passphraseEntropy)

        strengthIndicator.setProgress(strengthVal, animated: true)

        var strengthColour = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
        switch strength {
            case .veryWeak:
                strengthColour = UIColor(red:0.75, green:0.22, blue:0.17, alpha:1.0)
            case .weak:
                strengthColour = UIColor(red:0.90, green:0.49, blue:0.13, alpha:1.0)
            case .reasonable:
                strengthColour = UIColor(red:1.00, green:0.75, blue:0.28, alpha:1.0)
            case .strong:
                strengthColour = UIColor(red:0.13, green:0.81, blue:0.44, alpha:1.0)
            case .veryStrong:
                strengthColour = UIColor(red:0.03, green:0.68, blue:0.38, alpha:1.0)
        }
        strengthIndicator.progressTintColor = strengthColour
    }
    
    func validateInput() -> Bool {
        
        guard let name = name.text else { return false }
        guard let email = email.text else { return false }

        guard let passphrase1 = passphrase.text else { return false }
        guard let passphrase2 = passphraseConfirmation.text else { return false }
        
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

        guard (passphrase1 == passphrase2) else {
            alert(text: "Passphrases don't match!")
            return false
        }
        
        return true
    }
    
}
