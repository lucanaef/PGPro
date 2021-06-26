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
            tableView.reloadData()
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

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Yubikey"

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

        var rows: Int {
            switch self {
            case .about:
                return AboutSection.allCases.count
            case .configuration:
                return ConfigurationSection.allCases.count
            }
        }
    }

    private enum AboutSection: Int, CaseIterable {
        case version = 0
        case serialnumber = 1
    }

    private enum ConfigurationSection: Int, CaseIterable {
        case openPGPSupported = 0
        case openPGPEnabled = 1
    }

    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Sections(rawValue: section)?.rows ?? 0
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
            let row = ConfigurationSection(rawValue: indexPath.row)
            switch row {
            case .openPGPSupported:
                cell.textLabel?.text = "Supported"
                cell.detailTextLabel?.text = yubikey?.openPGPSupported?.description

            case .openPGPEnabled:
                cell.textLabel?.text = "Enabled"
                cell.detailTextLabel?.text = yubikey?.openPGPEnabled?.description

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
            return "OpenPGP via NFC"
        default:
            return nil
        }
    }


}
