//
//  SearchKeyserverViewController.swift
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
import SwiftUI
import ObjectivePGP

class SearchKeyserverViewController: UIViewController {

    var foundKeys = [(Key, String)]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self

        return tableView
    }()

    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.automaticallyShowsCancelButton = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false

        searchController.searchBar.placeholder = "Search by Email, Fingerprint or Key ID"
        searchController.searchBar.sizeToFit()
        searchController.searchBar.searchBarStyle = .prominent
        searchController.searchBar.delegate = self
        searchController.searchBar.keyboardType = .emailAddress
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no

        searchController.searchBar.showsBookmarkButton = true
        searchController.searchBar.setImage(UIImage(systemName: "qrcode"), for: .bookmark, state: .normal)

        return searchController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Search Keyserver"

        // Add buttons to navigation controller
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(addContactCancel(sender:))
        )

        // Add search bar to super view
        navigationItem.searchController = searchController

        // Add table view to super view
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    @objc
    func addContactCancel(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}

extension SearchKeyserverViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foundKeys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "searchKeyserverCell")
            else { return UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "searchKeyserverCell") }
        cell.selectionStyle = .none

        let key = foundKeys[indexPath.row].0
        let source = foundKeys[indexPath.row].1

        var primaryUser: User?
        if key.isSecret {
            guard let privateKey = key.secretKey else { return cell }
            primaryUser = privateKey.primaryUser
        } else {
            guard let publicKey = key.publicKey else { return cell }
            primaryUser = publicKey.primaryUser
        }
        if let primaryUser = primaryUser {
            cell.textLabel!.text = primaryUser.userID
            cell.detailTextLabel!.text = key.keyID.longIdentifier.insertSeparator(" ", atEvery: 4) + " – " + source
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let selectedKey = foundKeys[indexPath.row].0
        let result: ContactListResult = ContactListService.importFrom([selectedKey])

        self.alert(result) {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }

    }
}

extension SearchKeyserverViewController: UISearchBarDelegate {

    func switchVKIResult(result: Result<[Key], VerifyingKeyserverInterface.VKIError>) {
        let source = "OpenPGP Keyserver"

        switch result {
        case .failure(let error):
            switch error {
            case .invalidFormat:
                DispatchQueue.main.async {
                    self.alert(text: "Invalid Format")
                }
            case .invalidResponse:
                DispatchQueue.main.async {
                    self.alert(text: "Failed to get valid response from keyserver!")
                }
            case .keyNotFound:
                break
            case .keyNotSupported:
                break
            case .noConnection:
                DispatchQueue.main.async {
                    self.alert(text: "No Connection to Keyserver!")
                }
            case .rateLimiting:
                DispatchQueue.main.async {
                    self.alert(text: "Error due to Rate Limiting")
                }
            case .serverDatabaseMaintenance:
                DispatchQueue.main.async {
                    self.alert(text: "Keyserver is under Database Maintenanc")
                }
            }

        case .success(let keys):
            self.foundKeys = []
            for key in keys {
                self.foundKeys.append((key, source))
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tableView.reloadData()
        }
    }

    func switchWKDResult(result: Result<[Key], WebKeyDirectoryService.WKDError>) {
        let source = "Web Key Directory"

        switch result {
        case .failure(let error):
            switch error {
            case .keyNotSupported:
                DispatchQueue.main.async {
                    self.alert(text: "Found non-supported key!")
                }
            default:
                break
            }
        case .success(let keys):
            for key in keys {
                self.foundKeys.append((key, source))
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchBarText = searchBar.text else { return }
        self.foundKeys.removeAll() // remove previous search results

        if searchBarText.isValidEmail() { // case: email
            VerifyingKeyserverInterface.getByEmail(email: searchBarText) { result in
                self.switchVKIResult(result: result)
            }

            WebKeyDirectoryService.getByEmail(email: searchBarText) { result in
                self.switchWKDResult(result: result)
            }
        } else if searchBarText.count <= 18 { // case: key id
            VerifyingKeyserverInterface.getByKeyID(keyID: searchBarText) { (result) in
                self.switchVKIResult(result: result)
            }
        } else if searchBarText.count > 18 { // case: fingerprint
            VerifyingKeyserverInterface.getByFingerprint(fingerprint: searchBarText) { (result) in
                self.switchVKIResult(result: result)
            }
        }
    }

    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        let codeScannerView = CodeScannerView(codeTypes: [.qr], completion: self.handleScan)
        let codeScannerViewController = UIHostingController(rootView: codeScannerView)
        self.present(codeScannerViewController, animated: true)
    }

    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        dismiss(animated: true)
        switch result {
        case .success(let code):
            guard code.contains("OPENPGP4FPR:") else {
                self.alert(text: "Invalid QR Code!")
                return
            }
            let parsedCode = code.replacingOccurrences(of: "OPENPGP4FPR:", with: "")
            searchController.searchBar.text = parsedCode
            searchBarSearchButtonClicked(searchController.searchBar)
        case .failure:
            self.alert(text: "Scan failed!")
        }
    }

}

extension SearchKeyserverViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

}
