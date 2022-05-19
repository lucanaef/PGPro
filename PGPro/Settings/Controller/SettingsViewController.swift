//
//  SettingsViewController.swift
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

class SettingsViewController: UIViewController {

    private var settings = Settings()

    private let cellIdentifier = "SettingsViewController"
    lazy private var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        self.navigationController?.navigationBar.prefersLargeTitles = true

        // Add table view to super view
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
        tableView.reloadData()

    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Settings.Sections.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Settings.Sections(rawValue: section)?.header
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let section = Settings.Sections(rawValue: section), section == .preferences {
            if !Constants.User.canUseBiometrics {
                return "Disabled preferences are not available on this device."
            }
        }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Settings.Sections(rawValue: section)?.rows ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        guard let section = Settings.Sections(rawValue: indexPath.section) else {
            Log.s("IndexPath \(indexPath) out of bounds!")
            return cell
        }

        guard let setting = settings.allSettings[Settings.SettingsDictKey(section, indexPath.row)] else {
            Log.s("Setting for given section and subsection not found!")
            return cell
        }

        cell.textLabel?.text = setting.title
        cell.detailTextLabel?.text = setting.subtitle
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image = UIImage(systemName: setting.symbolName)

        switch setting.type {
        case .activity:
            cell.accessoryView = UIActivityIndicatorView(style: .medium)

        case .action:
            break

        case .preference:
            let toggle = PassableUISwitch()
            toggle.onTintColor = .secondaryLabel
            toggle.addTarget(self, action: #selector(self.switchStateDidChange(_:)), for: .valueChanged)
            toggle.params["setting"] = Settings.SettingsDictKey(section, indexPath.row)

            guard let toggleIsOn = setting.toggled else {
                Log.s("Toggle status for preference not set!")
                return cell
            }
            toggle.setOn(toggleIsOn, animated: false)

            guard let toggleIsEnabled = setting.enabled else {
                Log.s("Toggle not configured!")
                return cell
            }
            toggle.isEnabled = toggleIsEnabled
            if !toggleIsEnabled {
                cell.textLabel?.textColor = .secondaryLabel
            }

            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .link:
            cell.accessoryType = .disclosureIndicator

        case .segue:
            cell.accessoryType = .disclosureIndicator

        }

        return cell
    }

    @objc
    func switchStateDidChange(_ sender: PassableUISwitch!) {
        guard let settingsDictKey = sender.params["setting"] as? Settings.SettingsDictKey else {
            Log.s("Unable to get passed value (key) from switch")
            return
        }
        guard let setting = settings.allSettings[settingsDictKey] else {
            Log.s("Setting for given section and subsection not found!")
            return
        }
        setting.toggled = sender.isOn
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Settings.Sections(rawValue: indexPath.section) else {
            Log.s("IndexPath \(indexPath) out of bounds!")
            return
        }

        guard let setting = settings.allSettings[Settings.SettingsDictKey(section, indexPath.row)] else {
            Log.s("Setting for given section and subsection not found!")
            return
        }

        switch setting.type {
        case .activity:
            let cell = tableView.cellForRow(at: indexPath)
            guard let activityIndecator = cell?.accessoryView as? UIActivityIndicatorView else {
                Log.s("Cell not properly configured!")
                return
            }
            activityIndecator.startAnimating()
            setting.activity?(self) {
                DispatchQueue.main.async {
                    sleep(1)
                    activityIndecator.stopAnimating()
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
        case .action(let actionType):
            if actionType == Setting.ActionType.destructive {
                let dialogMessage = UIAlertController(title: "Are you sure?",
                                                      message: "",
                                                      preferredStyle: .alert)

                if let popoverController = dialogMessage.popoverPresentationController {
                    popoverController.sourceView = self.view
                    popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }

                let confirm = UIAlertAction(title: "Confirm", style: .destructive, handler: { (_) -> Void in
                    setting.action?()
                })
                let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in
                    return
                }
                dialogMessage.addAction(confirm)
                dialogMessage.addAction(cancel)
                self.present(dialogMessage, animated: true, completion: nil)
            } else {
                setting.action?()
            }
            tableView.deselectRow(at: indexPath, animated: true)
        case .preference:
            break
        case .link:
            AppStoreReviewService.incrementReviewWorthyActionCount()
            guard let url = setting.url else {
                Log.s("Cell not properly configured!")
                return
            }
            UIApplication.shared.open(url)
            tableView.deselectRow(at: indexPath, animated: true)
        case .segue:
            guard let viewController = setting.viewController else {
                Log.s("Cell not properly configured!")
                return
            }
            self.navigationController?.pushViewController(viewController, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }

    }
}
