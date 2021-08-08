//
//  YubikeyDetailViewController.swift
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

class YubikeyDetailViewController: UIViewController {

    private var yubikey: Yubikey? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private var smartCard: SmartCard? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private let cellIdentifier = "YubikeyDetailViewController"
    lazy private var tableView: UITableView = {
        let tableView = UITableView()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.alwaysBounceVertical = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "YubiKey"

        view.addSubview(tableView)
        tableView.pinEdges(to: view)
    }

    func setModel(to yubikey: Yubikey) {
        self.yubikey = yubikey
        tableView.reloadData()
    }

}

extension YubikeyDetailViewController: UITableViewDelegate, UITableViewDataSource {

    // View model
    private enum Sections: Int, CaseIterable {
        case about = 0
        case configuration = 1
        case keys = 2

        var rows: Int {
            switch self {
            case .about:
                return AboutSection.allCases.count
            case .configuration:
                return ConfigurationSection.allCases.count
            case .keys:
                return KeysSection.allCases.count
            }
        }
    }

    private enum AboutSection: Int, CaseIterable {
        case version = 0
        case serialnumber = 1
    }

    private enum ConfigurationSection: Int, CaseIterable {
        case nfc = 0
        case accessory = 1
    }

    private enum KeysSection: Int, CaseIterable {
        case loadKeys = 0
        case signing = 1
        case decryption = 2
        case authentication = 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Sections.keys.rawValue, smartCard == nil {
            return 1 // Only return "Load Keys" cell if keys have not yet been loaded
        } else {
            return Sections(rawValue: section)?.rows ?? 0
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        cell.selectionStyle = .none

        let section = Sections(rawValue: indexPath.section)

        switch section {
        case .about:
            let row = AboutSection(rawValue: indexPath.row)
            switch row {
            case .version:
                cell.textLabel?.text = "Version"
                cell.detailTextLabel?.text = yubikey?.version?.description
            case .serialnumber:
                cell.textLabel?.text = "Serial Number"
                cell.detailTextLabel?.text = yubikey?.serialNumber?.description

            default:
                Log.s("indexPath out of bounds!")
            }

        case .configuration:
            let capabilities = yubikey?.capabilities
            let row = ConfigurationSection(rawValue: indexPath.row)
            switch row {
            case .nfc:
                cell.textLabel?.text = "NFC"

                var label: String?
                var symbolName: String
                var tintColor: UIColor
                switch capabilities?.NFC {
                case .notSupported:
                    label = "Not Supported"
                    symbolName = "xmark.circle"
                    tintColor = UIColor.systemRed
                case .disabled:
                    label = "Disabled"
                    symbolName = "exclamationmark.circle"
                    tintColor = UIColor.systemOrange
                case .enabled:
                    label = "Enabled"
                    symbolName = "checkmark.circle"
                    tintColor = UIColor.systemGreen
                default:
                    label = nil
                    symbolName = "questionmark.circle"
                    tintColor = UIColor.label
                }
                cell.detailTextLabel?.text = label
                cell.imageView?.image = UIImage(systemName: symbolName)
                cell.imageView?.tintColor = tintColor

            case .accessory:
                cell.textLabel?.text = "Accessory"

                var label: String?
                var symbolName: String
                var tintColor: UIColor
                switch capabilities?.Accessory {
                case .notSupported:
                    label = "Not Supported"
                    symbolName = "xmark.circle"
                    tintColor = UIColor.systemRed
                case .disabled:
                    label = "Disabled"
                    symbolName = "exclamationmark.circle"
                    tintColor = UIColor.systemOrange
                case .enabled:
                    label = "Enabled"
                    symbolName = "checkmark.circle"
                    tintColor = UIColor.systemGreen
                default:
                    label = nil
                    symbolName = "questionmark.circle"
                    tintColor = UIColor.label
                }
                cell.detailTextLabel?.text = label
                cell.imageView?.image = UIImage(systemName: symbolName)
                cell.imageView?.tintColor = tintColor


            default:
                Log.s("indexPath out of bounds!")
            }

        case .keys:
            let row = KeysSection(rawValue: indexPath.row)
            switch row {
            case .loadKeys:
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Tap to load keys..."
                cell.textLabel?.textAlignment = .center
                cell.selectionStyle = .none
                return cell
            case .signing:
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.selectionStyle = .none
                cell.textLabel?.text = "Signing Key"

                let keyAlgorithm = smartCard?.signatureKey.algorithmAttributes?.algorithmID?.description
                if let keyAlgorithm = keyAlgorithm {
                    cell.textLabel?.text?.append(" (\(keyAlgorithm))")
                }

                cell.detailTextLabel?.text = smartCard?.signatureKey.fingerprint?.description
                cell.detailTextLabel?.textColor = .secondaryLabel

                var symbolName: String
                var tintColor: UIColor
                switch smartCard?.signatureKey.status {
                case .keyNotPresent:
                    symbolName = "xmark.circle"
                    tintColor = UIColor.systemRed
                case .keyImported:
                    symbolName = "checkmark.circle"
                    tintColor = UIColor.systemGreen
                case .keyGenerated:
                    symbolName = "checkmark.seal"
                    tintColor = UIColor.systemGreen
                default:
                    symbolName = "questionmark.circle"
                    tintColor = UIColor.label
                }
                cell.imageView?.image = UIImage(systemName: symbolName)
                cell.imageView?.tintColor = tintColor

                return cell
            case .decryption:
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.selectionStyle = .none
                cell.textLabel?.text = "Decryption Key"

                let keyAlgorithm = smartCard?.decryptionKey.algorithmAttributes?.algorithmID?.description
                if let keyAlgorithm = keyAlgorithm {
                    cell.textLabel?.text?.append(" (\(keyAlgorithm))")
                }

                cell.detailTextLabel?.text = smartCard?.decryptionKey.fingerprint?.description
                cell.detailTextLabel?.textColor = .secondaryLabel

                var symbolName: String
                var tintColor: UIColor
                switch smartCard?.decryptionKey.status {
                case .keyNotPresent:
                    symbolName = "xmark.circle"
                    tintColor = UIColor.systemRed
                case .keyImported:
                    symbolName = "checkmark.circle"
                    tintColor = UIColor.systemGreen
                case .keyGenerated:
                    symbolName = "checkmark.seal"
                    tintColor = UIColor.systemGreen
                default:
                    symbolName = "questionmark.circle"
                    tintColor = UIColor.label
                }
                cell.imageView?.image = UIImage(systemName: symbolName)
                cell.imageView?.tintColor = tintColor

                return cell
            case .authentication:
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.selectionStyle = .none
                cell.textLabel?.text = "Authentication Key"

                let keyAlgorithm = smartCard?.authenticationKey.algorithmAttributes?.algorithmID?.description
                if let keyAlgorithm = keyAlgorithm {
                    cell.textLabel?.text?.append(" (\(keyAlgorithm))")
                }

                cell.detailTextLabel?.text = smartCard?.authenticationKey.fingerprint?.description
                cell.detailTextLabel?.textColor = .secondaryLabel

                var symbolName: String
                var tintColor: UIColor
                switch smartCard?.authenticationKey.status {
                case .keyNotPresent:
                    symbolName = "xmark.circle"
                    tintColor = UIColor.systemRed
                case .keyImported:
                    symbolName = "checkmark.circle"
                    tintColor = UIColor.systemGreen
                case .keyGenerated:
                    symbolName = "checkmark.seal"
                    tintColor = UIColor.systemGreen
                default:
                    symbolName = "questionmark.circle"
                    tintColor = UIColor.label
                }
                cell.imageView?.image = UIImage(systemName: symbolName)
                cell.imageView?.tintColor = tintColor

                return cell

            default:
                Log.s("indexPath out of bounds!")
            }

        default:
            Log.s("indexPath out of bounds!")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = Sections(rawValue: section)
        switch (section) {
        case .about:
            return "About"
        case .configuration:
            return "OpenPGP Capabilities"
        case .keys:
            return "OpenPGP Keys"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == Sections.keys.rawValue) {
            if (indexPath.row == KeysSection.loadKeys.rawValue) {
                yubikey?.getSmartCard(completion: { result in
                    switch result {
                    case .failure(let error as YKError):
                        DispatchQueue.main.async {
                            self.alert(text: error.description)
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.alert(text: error.localizedDescription)
                        }
                    case .success(let smarCard):
                        self.smartCard = smarCard
                    }
                })
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == Sections.keys.rawValue) {
            if (indexPath.row == KeysSection.loadKeys.rawValue) {
                if (smartCard != nil) {
                    return 0.0
                }
            }
        }
        return 44.0
    }

}
