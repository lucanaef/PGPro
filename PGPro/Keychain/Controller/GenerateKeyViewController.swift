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

class GenerateKeyViewController: UIViewController {

    private let generateKey = GenerateKey() // model

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
        do {
            try generateKey.generate()
            dismiss(animated: true, completion: nil)
        } catch let error {
            switch error {
            case GenerateKeyError.nameNil, GenerateKeyError.nameEmpty:
                alert(text: "Name can't be empty!")
            case GenerateKeyError.emailAddressNil, GenerateKeyError.emailAddressEmpty:
                alert(text: "Email address can't be empty!")
            case GenerateKeyError.emailAddressInvalid:
                alert(text: "Email address invalid!")
            case GenerateKeyError.passphraseMismatch:
                alert(text: "Passphrases don't match!")
            case GenerateKeyError.nonUnique:
                alert(text: "Contact not unique!")
            default:
                alert(text: "Key generation failed!")
                Log.e(error)
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

}


extension GenerateKeyViewController: UITableViewDataSource, UITableViewDelegate {

    private struct TextFieldIdentifier {
        static let name = "TextFieldIdentifier.name"
        static let email = "TextFieldIdentifier.email"
        static let passphrase = "passphrase"
        static let confirmPassphrase = "confirmPassphrase"
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return GenerateKey.Sections.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GenerateKey.Sections(rawValue: section)?.rows ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return GenerateKey.Sections(rawValue: section)?.header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return GenerateKey.Sections(rawValue: section)?.footer
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = GenerateKey.Sections(rawValue: indexPath.section)
        if section == GenerateKey.Sections.security {
            let subsection = GenerateKey.SecuritySection(rawValue: indexPath.row)
            if subsection == GenerateKey.SecuritySection.passwordStength {
                return 5
            }
        }
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = GenerateKey.Sections(rawValue: indexPath.section)
        let cell = FullTextFieldTableViewCell()

        cell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cell.textField.addKeyboardDismissButton(target: self, selector: #selector(tapDone(sender:)))
        cell.selectionStyle = .none

        switch section {
        case .contact:
            let subsection = GenerateKey.ContactSection(rawValue: indexPath.row)
            cell.textField.placeholder = subsection?.placeholder

            switch subsection {
            case .name:
                cell.textField.textContentType = .name
                cell.textField.autocapitalizationType = .words
                cell.textField.identifier = TextFieldIdentifier.name
            case .email:
                cell.textField.textContentType = .emailAddress
                cell.textField.keyboardType = .emailAddress
                cell.textField.autocapitalizationType = .none
                cell.textField.identifier = TextFieldIdentifier.email
            default:
                Log.e("IndexPath out of bounds!")
            }

        case .security:
            let subsection = GenerateKey.SecuritySection(rawValue: indexPath.row)
            cell.textField.placeholder = subsection?.placeholder
            cell.textField.isSecureTextEntry = true

            switch subsection {
            case .passphrase:
                cell.textField.textContentType = .newPassword
                cell.textField.identifier = TextFieldIdentifier.passphrase
            case .confirmPassphrase:
                cell.textField.textContentType = .password
                cell.textField.identifier = TextFieldIdentifier.confirmPassphrase
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
    private func tapDone(sender: Any) {
        view.endEditing(true)
    }

    @objc
    func textFieldDidChange(_ textField: TextField) {
        switch textField.identifier {
        case TextFieldIdentifier.name:
            generateKey.name = textField.text
        case TextFieldIdentifier.email:
            generateKey.email = textField.text
        case TextFieldIdentifier.passphrase:
            generateKey.passphrase = textField.text
            updateStrengthIndicator(for: textField.text)
        case TextFieldIdentifier.confirmPassphrase:
            generateKey.confirmedPassphrase = textField.text
        default:
            Log.e("Unrecognized TestField")
        }
    }


}
