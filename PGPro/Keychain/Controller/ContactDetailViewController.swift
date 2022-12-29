//
//  ContactDetailViewController.swift
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

class ContactDetailViewController: UIViewController {

    private var contactDetails: ContactDetails? {
        didSet {
            tableView.reloadData()
        }
    }

    private var saveButtonAdded = false
    private var changedContactName: String?

    private let cellIdentifier = "ContactDetailViewController"
    lazy private var tableView: UITableView = {
        let tableView = UITableView()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.alwaysBounceVertical = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()

        return tableView
    }()

    private let formatter = ISO8601DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = contactDetails?.keyID

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up")?.withTintColor(UIColor.label),
            style: .plain,
            target: self,
            action: #selector(setShare)
        )

        formatter.formatOptions = .withFullDate

        // Add table view to super view
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
        tableView.reloadData()
    }

    func setModel(to contactDetails: ContactDetails) {
        self.contactDetails = contactDetails
        tableView.reloadData()
    }

    @objc
    func setShare() {
        let optionMenu = UIAlertController(title: nil, message: "Select Key to Share", preferredStyle: .actionSheet)
        optionMenu.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem

        let sharePublicKeyAction = UIAlertAction(title: "Public Key", style: .default) { _ in
            let activityItem = self.contactDetails?.armoredPublicKey as Any
            optionMenu.dismiss(animated: true, completion: nil)
            self.share(activityItems: [activityItem])
        }

        let sharePrivateKeyAction = UIAlertAction(title: "Private Key", style: .destructive) { _ in
            let activityItem = self.contactDetails?.armoredPrivateKey as Any
            optionMenu.dismiss(animated: true, completion: nil)
            self.share(activityItems: [activityItem])
        }

        let shareBothAction = UIAlertAction(title: "Share Both", style: .destructive) { _ in
            let activityItem = (self.contactDetails?.armoredPublicKey ?? "") + (self.contactDetails?.armoredPrivateKey ?? "") as Any
            optionMenu.dismiss(animated: true, completion: nil)
            self.share(activityItems: [activityItem])
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            optionMenu.dismiss(animated: true, completion: nil)
            return
        }

        switch contactDetails?.keyType {
        case "Public & Private":
            optionMenu.addAction(sharePublicKeyAction)
            optionMenu.addAction(sharePrivateKeyAction)
            optionMenu.addAction(shareBothAction)
            optionMenu.addAction(cancelAction)
            present(optionMenu, animated: true, completion: nil)
        case "Private":
            optionMenu.addAction(sharePrivateKeyAction)
            optionMenu.addAction(cancelAction)
            present(optionMenu, animated: true, completion: nil)
        case "Public":
            optionMenu.addAction(sharePublicKeyAction)
            optionMenu.addAction(cancelAction)
            present(optionMenu, animated: true, completion: nil)
        default:
            let activityItem = contactDetails?.armoredPublicKey as Any
            self.share(activityItems: [activityItem])
        }
    }

    func share(activityItems: [Any]) {
        AppStoreReviewService.incrementReviewWorthyActionCount()

        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem

        present(activityVC, animated: true, completion: nil)
    }

}

extension ContactDetailViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Sections: Int, CaseIterable {
        case contact = 0
        case key = 1

        var rows: Int {
            switch self {
            case .contact:
                return ContactSection.allCases.count
            case .key:
                return KeySection.allCases.count
            }
        }
    }

    private enum ContactSection: Int, CaseIterable {
        case name = 0
        case email = 1
    }

    private enum KeySection: Int, CaseIterable {
        case id = 0
        case type = 1
        case expires = 2
        case fingerprint = 3
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        let hasValidKey = contactDetails?.keyIsValid ?? false
        if hasValidKey {
            return Sections.allCases.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = Sections(rawValue: section)
        switch section {
        case .contact:
            return NSLocalizedString("User Info", comment: "The section header of the user info section in keychain tab")
        case .key:
            return NSLocalizedString("Primary Key", comment: "The section header of the primary key section in keychain tab")
        default:
            Log.s("indexPath out of bounds!")
            return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Sections(rawValue: section)?.rows ?? 0
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView,
                   canPerformAction action: Selector,
                   forRowAt indexPath: IndexPath,
                   withSender sender: Any?) -> Bool {

        let section = Sections(rawValue: indexPath.section)
        if section == .key {
            return action == #selector(UIResponderStandardEditActions.copy(_:))
        }

        return false
    }

    func tableView(_ tableView: UITableView,
                   performAction action: Selector,
                   forRowAt indexPath: IndexPath,
                   withSender sender: Any?) {
        if let cell = tableView.cellForRow(at: indexPath) {
            UIPasteboard.general.string = cell.detailTextLabel?.text
        }
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        changedContactName = textField.text
        if !saveButtonAdded {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                                     target: self,
                                                                     action: #selector(renameContactAction)
            )
            saveButtonAdded = true
        }
    }

    @objc
    func renameContactAction() {
        do {
            try contactDetails?.rename(to: changedContactName)
            _ = navigationController?.popViewController(animated: true)
        } catch let error {
            switch error {
            case ContactDetails.RenameError.cantBeNil:
                Log.e("Failed to rename contact: \(error)")
            case ContactDetails.RenameError.cantBeEmpty:
                alert(
                    text: NSLocalizedString(
                        "Name can't be empty!",
                        comment: "The alert prompted when attempting to rename contact with an empty name."
                    )

                )
            case ContactDetails.RenameError.alreadyExists:
                alert(
                    text: NSLocalizedString(
                        "A contact with this name and email address already exists!",
                        comment: "The alert prompted when attempting to rename contact with a duplicate name and/or address."
                    )
                )
            default:
                Log.e("Failed to rename contact: \(error)")
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let section = Sections(rawValue: indexPath.section)

        var cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)

        switch section {
        case .contact:
            let row = ContactSection(rawValue: indexPath.row)
            switch row {
            case .name:
                let nameCell = FDTextFieldTableViewCell(style: .value1, reuseIdentifier: "FDTextFieldTableViewCell")
                nameCell.textLabel?.text = NSLocalizedString(
                    "Name",
                    comment: """
                    The title of the name cell in contact details.
                    """
                )
                nameCell.textField.text = contactDetails?.name
                nameCell.textField.textColor = .secondaryLabel
                nameCell.textField.clearButtonMode = .whileEditing
                nameCell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
                cell = nameCell
            case .email:
                cell.textLabel?.text = NSLocalizedString(
                    "Email",
                    comment: """
                    The title of the email cell in contact details.
                    """
                )
                cell.detailTextLabel?.text = contactDetails?.email
            default:
                Log.s("indexPath out of bounds!")
            }

        case .key:
            let row = KeySection(rawValue: indexPath.row)
            switch row {
            case .id:
                cell.textLabel?.text = NSLocalizedString(
                    "ID",
                    comment: """
                    The title of the ID cell in key section within contact details.
                    """
                )
                cell.detailTextLabel?.text = contactDetails?.keyID
            case .type:
                cell.textLabel?.text = NSLocalizedString(
                    "Type",
                    comment: """
                    The title of the type cell in key section within contact details.
                    """
                )
                cell.detailTextLabel?.text = contactDetails?.keyType
            case .expires:
                cell.textLabel?.text = NSLocalizedString(
                    "Expires",
                    comment: """
                    The title of the expires cell in key section within contact details.
                    """
                )
                let date = contactDetails?.keyExpirationDate
                cell.detailTextLabel?.text = NSLocalizedString(
                    "Never",
                    comment: """
                    The description of a never-expiring key in key section within contact details.
                    """
                )
                if let date = date {
                    cell.detailTextLabel?.text = formatter.string(for: date)
                    if date < Date() {
                        cell.detailTextLabel?.textColor = UIColor.red
                    }
                }
            case .fingerprint:
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
                cell.textLabel?.text = NSLocalizedString(
                    "Fingerprint",
                    comment: """
                    The title of the fingerprint cell in contact details.
                    """
                )
                cell.detailTextLabel?.text = contactDetails?.keyFingerprint
                cell.detailTextLabel?.textColor = .secondaryLabel
            default:
                Log.s("indexPath out of bounds!")
            }

        default:
            Log.s("indexPath out of bounds!")
        }

        cell.selectionStyle = .none
        return cell

    }

}
