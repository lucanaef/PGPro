//
//  LicensesViewController.swift
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

class LicensesViewController: UIViewController {

    private let licenses = Licenses.allLicenses

    private let cellIdentifier = "LicensesViewController"
    lazy private var tableView: UITableView = {
        let tableView = UITableView()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.alwaysBounceVertical = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Licenses"

        // Add table view to super view
        view.addSubview(tableView)
        tableView.pinEdges(to: view)
        tableView.reloadData()
    }

}

extension LicensesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return licenses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let license = licenses[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        cell.textLabel?.text = license.title
        cell.detailTextLabel?.text = license.subtitle
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let license = licenses[indexPath.row]
        UIApplication.shared.open(license.licenseURL)
        tableView.deselectRow(at: indexPath, animated: true)
    }




}
