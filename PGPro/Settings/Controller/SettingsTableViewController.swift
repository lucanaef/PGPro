//
//  SettingsTableViewController.swift
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
import StoreKit
import ObjectivePGP // TODO: should not be needed in view controller...

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak private var exportActivityIndicator: UIActivityIndicatorView!

    var url = URL(string: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0) { // Case: Export Keychain

            exportActivityIndicator.startAnimating()

            DispatchQueue.global(qos: .default).async {

                let keyring = Keyring()
                var keys: [Key] = []
                for cntct in ContactListService.get(ofType: .both) {
                    keys.append(cntct.key)
                }
                keyring.import(keys: keys)

                DispatchQueue.main.async { [weak self] in

                    let file = "\(Date().toString())-keychain.gpg"
                    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let fileURL = dir.appendingPathComponent(file)
                        do {
                            try keyring.export().write(to: fileURL)
                        } catch {
                            self?.alert(text: "Export failed!")
                        }

                        // Share file
                        var filesToShare = [Any]()
                        filesToShare.append(fileURL)
                        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                        self?.present(activityViewController, animated: true, completion: nil)

                    } else {
                        self?.alert(text: "Export failed!")
                    }
                }

                DispatchQueue.main.async { [weak self] in
                    self?.exportActivityIndicator.stopAnimating()
                }
            }

        } else if (indexPath.section == 1) { // Case: Send Feedback to Licenses
            
            switch indexPath.row {
            case 0: // Send Feedback
                AppStoreReviewService.incrementReviewWorthyActionCount()
                url = URL(string: "mailto:dev@pgpro.app?subject=%5BPGPro%20\(Constants.PGPro.version ?? "")%5D%20Feedback")
                if let url = url {
                    UIApplication.shared.open(url)
                }
            case 1: // contribute
                url = URL(string: "https://github.com/lucanaef/PGPro")
                if let url = url {
                    UIApplication.shared.open(url)
                }
            case 2: // Rate PGPro
                url = URL(string: "https://itunes.apple.com/app/id" + Constants.PGPro.appID + "?action=write-review")
                if let url = url {
                    UIApplication.shared.open(url)
                }
            case 3: // Software Licenses

                // TODO: Use separate table view for this...

                url = Bundle.main.url(forResource: "licenses", withExtension: "html")
                guard let url = url else { return }
                let destVC = WebViewController()
                navigationController?.pushViewController(destVC, animated: true)
                let urlRequest = URLRequest(url: url)
                destVC.loadRequest(urlRequest)
            default:
                return
            }
            
        } else if (indexPath.section == 2) { // Case: Delete All Data
            
            let dialogMessage = UIAlertController(title: "Are you sure you want to delete all keys?",
                                                  message: "",
                                                  preferredStyle: .alert)
            
            // Create OK button with action handler
            let confirm = UIAlertAction(title: "Confirm", style: .destructive, handler: { (_) -> Void in
                ContactListService.deleteAllData()
            })
            
            // Create Cancel button with action handlder
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) -> Void in
                return
            }
            
            // Add Confirm and Cancel button to dialog message
            dialogMessage.addAction(confirm)
            dialogMessage.addAction(cancel)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)

            AppStoreReviewService.incrementReviewWorthyActionCount()

            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 1 && indexPath.row == 2) { // Rate PGPro
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            cell.detailTextLabel!.text = "\(Constants.PGPro.numRatings) PEOPLE HAVE RATED THIS VERSION"
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

}
