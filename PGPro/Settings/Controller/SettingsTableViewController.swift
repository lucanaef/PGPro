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

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
    
    var url = URL(string: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        let appLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0,
                                                             y: self.view.frame.height - 150),
                                             size: CGSize(width: self.view.frame.width, height: 20))
        )
        appLabel.text = "PGPro " + Constants.PGPro.version
        appLabel.textAlignment = .center
        appLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        appLabel.textColor = UIColor(red: 0.24, green: 0.24, blue: 0.26, alpha: 1.0)
        self.navigationController?.view.addSubview(appLabel)
        
        let authorLabel = UILabel(frame: CGRect(x: 0,
                                                y: self.view.frame.height - 130,
                                                width: self.view.frame.width,
                                                height: 20)
        )
        authorLabel.text = "by Luca Näf"
        authorLabel.textAlignment = .center
        authorLabel.font = UIFont.systemFont(ofSize: 14.0)
        authorLabel.textColor = UIColor(red:0.24, green:0.24, blue:0.26, alpha:1.0)
        self.navigationController?.view.addSubview(authorLabel)
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == 0) {
            
            activityIndicator.startAnimating()

            DispatchQueue.global(qos: .default).async {

                let addedContacts = ContactImportService.importContacts()
                
                DispatchQueue.main.async { [weak self] in
                    if (addedContacts == -1) {
                        self?.alert(text: "Import Requires an Internet Connection!")
                    } else if (addedContacts == 0) {
                        self?.alert(text: "No New Contacts Added!")
                    } else if (addedContacts == 1) {
                        self?.alert(text: "1 Contact Added!")
                    } else {
                        self?.alert(text: String(addedContacts) + " Contacts Added!")
                    }
                }
                
               DispatchQueue.main.async { [weak self] in
                    // UI updates must be on main thread
                    self?.activityIndicator.stopAnimating()
                }
            }

        } else if (indexPath.section == 1) {
            
            switch indexPath.row {
            case 0: // Send Feedback
                url = URL(string: "mailto:dev@pgpro.app?subject=%5BPGPro%5D%20Feedback")
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
                url = Bundle.main.url(forResource: "licenses", withExtension: "html")
                guard url != nil else { return }
                performSegue(withIdentifier: "goToWebView", sender: nil)
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
        
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destVC = segue.destination as? WebViewController else { return }
        guard let url = url else { return }
        destVC.urlRequest = URLRequest(url: url)
    }

}
