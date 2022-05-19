//
//  MailIntegrationViewController.swift
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

class MailIntegrationViewController: UIViewController {

    lazy var mailIntegrationTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .insetGrouped)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Mail Integration"
        self.navigationController?.navigationBar.prefersLargeTitles = true

        // Add table view to super view
        view.addSubview(mailIntegrationTableView)
        mailIntegrationTableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        mailIntegrationTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mailIntegrationTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        mailIntegrationTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

}

extension MailIntegrationViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MailIntegration.isEnabled ? MailIntegration.clients.count + 1 : 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Mail Integration"
            let switchView = UISwitch(frame: .zero)
            switchView.setOn(MailIntegration.isEnabled, animated: true)
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
            return cell
        default:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MailIntegrationTableViewCell")
            let client = MailIntegration.clients[indexPath.row - 1]

            cell.textLabel?.text = client.name
            cell.imageView?.image = UIImage(named: client.name)?.resized(to: CGSize(width: 30, height: 30))

            cell.imageView?.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
            cell.imageView?.layer.cornerRadius = 5.0

            if client == .systemDefault {
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.text = "Default email app"
            }

            if !MailIntegration.isAvailable(client) {
                cell.textLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.textColor = UIColor.secondaryLabel
                cell.detailTextLabel?.text = "Not Installed"
            }

            if client == MailIntegration.selectedClient {
                cell.accessoryType = .checkmark
            }

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            return
        default:
            MailIntegration.selectedClient = MailIntegration.clients[indexPath.row - 1]
        }
        mailIntegrationTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.row {
        case 0:
            return false
        default:
            let client = MailIntegration.clients[indexPath.row - 1]
            return MailIntegration.isAvailable(client)
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch MailIntegration.isEnabled {
        case true:
            return nil
        case false:
            return "If 'Mail Integration' is enabled, PGPro will open the selected mail client after encrypting a message."
        }
    }

    @objc
    func switchChanged(_ sender: UISwitch!) {
        MailIntegration.isEnabled = sender.isOn
        mailIntegrationTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }

}
