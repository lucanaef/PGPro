//
//  GenerateKeyViewController.swift
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
import ObjectivePGP

class GenerateKeyViewController: UIViewController {

    private let cellIdentifier = "GenerateKeyViewController"
    lazy private var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        return tableView
    }()

    lazy private var strengthIndicator: UIProgressView = {
        let strengthIndicator = UIProgressView(progressViewStyle: .bar)
        strengthIndicator.translatesAutoresizingMaskIntoConstraints = false
        strengthIndicator.setProgress(0, animated: false)
        return strengthIndicator
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Generate Key Pair"

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

        // Add table view to super view
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
        tableView.reloadData()
    }

    @objc
    func addContactDone(sender: UIBarButtonItem) {
        if validateInput() {
            guard let name = name else { return }
            guard let email = email else { return }
            let userID = "\(name) <\(email)>"

            // Generate Key
            let keyGen = KeyGenerator()
            let pass = passphrase != "" ? passphrase : nil
            let key = keyGen.generate(for: userID, passphrase: pass)

            // Create Contact
            let result = ContactListService.add(name: name, email: email, key: key)

            if (result.unsupported == 1) {
                alert(text: "Key format is currently not supported!")
            } else if (result.duplicates == 1) {
                alert(text: "Contact with this email address already exists!")
            } else {
                AppStoreReviewService.incrementReviewWorthyActionCount()
                dismiss(animated: true, completion: nil)
            }
        }
    }

    @objc
    func addContactCancel(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    private func updateStrengthIndicator(for text: String?) {
        let passphraseEntropy = Navajo.entropy(of: text ?? "")
        // Normalized estimated passphrase strength value
        let strengthVal = min(128.0, passphraseEntropy) / 128.0
        let strength = Navajo.passwordStrength(forEntropy: passphraseEntropy)

        strengthIndicator.setProgress(strengthVal, animated: true)

        var strengthColour = UIColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)
        switch strength {
        case .veryWeak:
            strengthColour = UIColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1.0)
        case .weak:
            strengthColour = UIColor(red: 0.90, green: 0.49, blue: 0.13, alpha: 1.0)
        case .reasonable:
            strengthColour = UIColor(red: 1.00, green: 0.75, blue: 0.28, alpha: 1.0)
        case .strong:
            strengthColour = UIColor(red: 0.13, green: 0.81, blue: 0.44, alpha: 1.0)
        case .veryStrong:
            strengthColour = UIColor(red: 0.03, green: 0.68, blue: 0.38, alpha: 1.0)
        }
        strengthIndicator.progressTintColor = strengthColour
    }

    func validateInput() -> Bool {
        guard let name = name else { return false }
        guard let email = email else { return false }

        guard let passphrase1 = passphrase else { return false }
        guard let passphrase2 = confirmedPassphrase else { return false }

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


    // Model properties
    private var name: String?
    private var email: String?
    private var passphrase: String?
    private var confirmedPassphrase: String?

}


extension GenerateKeyViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Sections: Int, CaseIterable {
        case contact = 0
        case security = 1

        var rows: Int {
            switch self {
                case .contact:
                    return ContactSection.allCases.count
                case .security:
                    return SecuritySection.allCases.count
            }
        }

        var header: String? {
            switch self {
                case .contact:
                    return ContactSection.header
                case .security:
                    return SecuritySection.header
            }
        }

        var footer: String? {
            switch self {
                case .contact:
                    return ContactSection.footer
                case .security:
                    return SecuritySection.footer
            }
        }

    }

    private enum ContactSection: Int, CaseIterable {
        case name = 0
        case email = 1

        static var header: String? {
            "Contact Info"
        }

        static var footer: String? {
            nil
        }

        var placeholder: String? {
            switch self {
            case .name:
                return "Name"
            case .email:
                return "Email Address"
            }
        }
    }

    private enum SecuritySection: Int, CaseIterable {
        case passphrase = 0
        case confirmPassphrase = 1
        case passwordStength = 2

        static var header: String? {
            "Security"
        }

        static var footer: String? {
            "Note: If you forget your passphrase, there is no way to recover it."
        }

        var placeholder: String? {
            switch self {
            case .passphrase:
                return "Passphrase"
            case .confirmPassphrase:
                return "Confirm Passphrase"
            case .passwordStength:
                return nil
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Sections(rawValue: section)?.rows ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Sections(rawValue: section)?.header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return Sections(rawValue: section)?.footer
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Sections(rawValue: indexPath.section)
        if section == Sections.security {
            let subsection = SecuritySection(rawValue: indexPath.row)
            if subsection == SecuritySection.passwordStength {
                return 5
            }
        }
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Sections(rawValue: indexPath.section)
        let cell = FullTextFieldTableViewCell()

        cell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cell.selectionStyle = .none

        switch section {
        case .contact:
            let subsection = ContactSection(rawValue: indexPath.row)
            cell.textField.placeholder = subsection?.placeholder

            switch subsection {
            case .name:
                cell.textField.textContentType = .name
                cell.textField.autocapitalizationType = .words
                cell.textField.identifier = "name"
            case .email:
                cell.textField.textContentType = .emailAddress
                cell.textField.keyboardType = .emailAddress
                cell.textField.autocapitalizationType = .none
                cell.textField.identifier = "email"
            default:
                Log.e("IndexPath out of bounds!")
            }

        case .security:
            let subsection = SecuritySection(rawValue: indexPath.row)
            cell.textField.placeholder = subsection?.placeholder
            cell.textField.isSecureTextEntry = true

            switch subsection {
            case .passphrase:
                cell.textField.textContentType = .newPassword
                cell.textField.identifier = "passphrase"
            case .confirmPassphrase:
                cell.textField.textContentType = .password
                cell.textField.identifier = "confirmPassphrase"
            case .passwordStength:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
                cell.selectionStyle = .none
                cell.contentView.addSubview(strengthIndicator)
                strengthIndicator.pinEdges(to: cell.contentView)
                return cell
            default:
                Log.e("IndexPath out of bounds!")
            }

        default:
            Log.e("IndexPath out of bounds!")
        }

        return cell
    }

    @objc
    func textFieldDidChange(_ textField: TextField) {
        switch textField.identifier {
        case "name":
            name = textField.text
        case "email":
            email = textField.text
        case "passphrase":
            passphrase = textField.text
            updateStrengthIndicator(for: passphrase)
        case "confirmPassphrase":
            confirmedPassphrase = textField.text
        default:
            Log.e("Unrecognized TestField")
        }
    }


}

