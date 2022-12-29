//
//  DecryptionViewController.swift
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

class DecryptionViewController: UIViewController {

    private let cellIdentifier = "DecryptionViewController"

    private var decryptionContact: Contact?
    private var encryptedMessage: String? {
        didSet { updateView() }
    }
    private var passphrase: String?
    private var selectionLabel = NSLocalizedString(
        "Select Private Key...",
        comment: """
        The label of select private key option in the decrypt tab.
        """
    )

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
        textView.isEditable = false

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
        // hack to make sure the imageView inside the table view cells are properly sized
        tableView.reloadData()
    }

    func setMessageField(to message: String?) {
        encryptedMessage = message
    }

    private func setupView() {
        self.tabBarItem.title = NSLocalizedString(
            "Decryption",
            comment: """
            The title of the bar item of select private key option in the decrypt tab.
            """
        )
        self.navigationItem.title = NSLocalizedString(
            "Decrypt Message",
            comment: """
            The navigation title of the decrypt tab.
            """
        )
        self.navigationController?.navigationBar.prefersLargeTitles = true
        let decryptButton = UIBarButtonItem(
            image: UIImage(systemName: "envelope.open.fill")?.withTintColor(UIColor.label),
            style: .done,
            target: self,
            action: #selector(decrypt)
        )
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "trash")?.withTintColor(UIColor.label),
            style: .plain,
            target: self,
            action: #selector(clearView)
        )
        navigationItem.rightBarButtonItems = [decryptButton, clearButton]

        // Add table view to super view
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
    }

    @objc
    private func updateView() {
        var label = NSLocalizedString(
            "Select Private Key...",
            comment: """
            The label to prompt user to choose a private key within the decrypt tab
            """
        )

        if let decryptionContact = decryptionContact {
            label = decryptionContact.userID
        }
        selectionLabel = label
        textView.text = encryptedMessage
        tableView.reloadData()
    }

    @objc
    private func clearView() {
        let dialogMessage = UIAlertController(
            title: NSLocalizedString(
                "Delete this message",
                comment: """
                The confirmation dialogue text to delete the message that would have been decrypted.
                """
            ),
            message: "",
            preferredStyle: .alert
        )

        // Create OK button with action handler
        let confirm = UIAlertAction(
            title: NSLocalizedString(
                "Confirm",
                comment: """
                The button to confirm the clearing of text within decrypttion tab.
                """
            ),
            style: .destructive
        ) { (_) -> Void in
            self.decryptionContact = nil
            self.encryptedMessage = nil
            self.passphrase = nil
            self.updateView()
        }

        // Create Cancel button with action handlder
        let cancel = UIAlertAction(
            title: NSLocalizedString(
                "Cancel",
                comment: """
                The button to cancel the clearing of text within decrypttion tab.
                """
            ),
            style: .cancel
        ) { (_) -> Void in
            return
        }

        // Add Confirm and Cancel button to dialog message
        dialogMessage.addAction(confirm)
        dialogMessage.addAction(cancel)

        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
    }

    @objc
    private func resetSelection() {
        decryptionContact = nil
        updateView()
    }

    @objc
    private func decrypt() {
        guard let encryptedMessage = encryptedMessage else { return }
        guard let decryptionContact = decryptionContact else {
            alert(
                text: NSLocalizedString(
                    "No Private Key Selected!",
                    comment: """
                    The button to cancel the clearing of text within decrypttion tab.
                    """
                )
            )
            return
        }

        // Load stored passphrase
        if decryptionContact.keyRequiresPassphrase, let storesPassphrase = try? decryptionContact.storesPassphrase(), storesPassphrase {
            let passphraseRequest = decryptionContact.getPassphrase()
            switch passphraseRequest {
            case .success(let pass):
                passphrase = pass
            case .failure(let error):
                Log.e(error)
            }
        }

        do {
            let decryptedMessage = try CryptographyService.decrypt(
                message: encryptedMessage,
                by: decryptionContact,
                withPassphrase: passphrase
            )
            present(decryptedMessage)
        } catch let error {
            switch error {
            case CryptographyError.emptyMessage:
                alert(
                    text: NSLocalizedString(
                        "Please enter message first!",
                        comment: """
                        The alert text prompted when the message is empty in the decryption tab.
                        """
                    )
                )
            case CryptographyError.invalidMessage:
                alert(
                    text: NSLocalizedString(
                        "Message is invalid!",
                        comment: """
                        The alert text prompted when the message is invalid in the decryption tab.
                        """
                    )
                )
            case CryptographyError.requiresPassphrase:
                alert(
                    text: NSLocalizedString(
                        "Decryption requires passphrase!",
                        comment: """
                        The alert text prompted when the decryption requires a passphrase in the decryption tab.
                        """
                    )
                )
            case CryptographyError.wrongPassphrase:
                alert(
                    text: NSLocalizedString(
                        "Wrong passphrase!",
                        comment: """
                        The alert text prompted when the passphrase is incorrect in the decryption tab.
                        """
                    )
                )
            case CryptographyError.frameworkError(let frameworkError):
                alert(
                    text: NSLocalizedString(
                        "Decryption failed!",
                        comment: """
                        The alert text prompted when the decryption failed (due to framework error)
                        in the decryption tab.
                        """
                    )
                )
                Log.e(frameworkError)
            case CryptographyError.failedDecryption:
                alert(
                    text: NSLocalizedString(
                        "Decryption failed!",
                        comment: """
                        The alert text prompted when the decryption failed in the decryption tab.
                        """
                    )
                )
            default:
                alert(
                    text: NSLocalizedString(
                        "Decryption failed!",
                        comment: """
                        The alert text prompted when the decryption failed in the decryption tab.
                        """
                    )
                )
                Log.e(error)
            }
            return
        }
    }

    private func present(_ message: String) {
        let decryptedMessageViewController = DecryptedMessageViewController()
        decryptedMessageViewController.show(message)

        // Embed view in a new navigation controller as a
        //  workaround to https://forums.developer.apple.com/thread/121861
        let decryptedMessageNavigation = UINavigationController()
        decryptedMessageNavigation.setViewControllers([decryptedMessageViewController], animated: false)
        decryptedMessageNavigation.modalPresentationStyle = .automatic

        // https://stackoverflow.com/a/69135729
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }

        self.present(decryptedMessageNavigation, animated: true, completion: nil)
    }

}

extension DecryptionViewController: UITableViewDataSource, UITableViewDelegate {

    enum DecryptionRows: Int, CaseIterable {
        case keySelection = 0
        case passphrase = 1
        case pasteFromClipboard = 2
        case message = 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DecryptionRows.allCases.count
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        passphrase = textField.text
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        cell.selectionStyle = .none

        switch indexPath.row {
        case DecryptionRows.keySelection.rawValue:
            cell.textLabel?.text = selectionLabel
            cell.accessoryType = .disclosureIndicator
        case DecryptionRows.passphrase.rawValue:
            let passphraseCell = FullTextFieldTableViewCell(style: .value1, reuseIdentifier: "FDTextFieldTableViewCell")
            passphraseCell.textField.placeholder = NSLocalizedString("Passphrase", comment: "The placeholder text of the passphrase text field")
            passphraseCell.textField.text = passphrase
            passphraseCell.textField.clearButtonMode = .never
            passphraseCell.textField.textContentType = .password
            passphraseCell.textField.isSecureTextEntry = true
            passphraseCell.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
            cell = passphraseCell
        case DecryptionRows.pasteFromClipboard.rawValue:
            cell.textLabel?.text = NSLocalizedString(
                " Paste from Clipboard",
                comment: """
                The text that prompts the option of pasting from clipboard
                """
            )
            if let symbol = UIImage(systemName: "doc.on.clipboard"), let imageView = cell.imageView {
                imageView.image = symbol.withTintColor(UIColor.label)
            }
        case DecryptionRows.message.rawValue:
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 10000) // hack way to hide last separator
            let cellView = cell.contentView
            cellView.addSubview(textView)
            textView.pinEdges(to: cellView)
        default:
            Log.s("indexPath \(indexPath) out of bounds!")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case DecryptionRows.keySelection.rawValue:
            let keySelectionViewController = KeySelectionViewController()
            keySelectionViewController.set(toType: .privateKey)
            keySelectionViewController.delegate = self
            navigationController?.pushViewController(keySelectionViewController, animated: true)
        case DecryptionRows.pasteFromClipboard.rawValue:
            encryptedMessage = UIPasteboard.general.string
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            Log.s("indexPath \(indexPath) out of bounds!")
        }

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var keyRequiresAskingForPassphrase = decryptionContact?.keyRequiresPassphrase ?? false
        if keyRequiresAskingForPassphrase, let storedPassphrase = try? decryptionContact?.storesPassphrase(), storedPassphrase {
            keyRequiresAskingForPassphrase = false
        }

        switch indexPath.row {
        case DecryptionRows.passphrase.rawValue:
            return (keyRequiresAskingForPassphrase ? 44 : 0)
        case DecryptionRows.message.rawValue:
            var height = self.view.frame.height
            height -= (keyRequiresAskingForPassphrase ? 132 : 88) // table view cells above
            height -= (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0)
            height -= (self.navigationController?.navigationBar.frame.height ?? 0.0)
            height -= (self.tabBarController?.tabBar.frame.size.height ?? 0.0)
            return height
        default:
            return 44
        }
    }

}

extension DecryptionViewController: KeySelectionDelegate {

    func update(selected: [Contact], for type: Constants.KeyType) {
        decryptionContact = selected.isEmpty ? nil : selected[0]
        self.updateView()
    }

}
