//
//  DecryptedMessageViewController.swift
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

class DecryptedMessageViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    var message: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let text = message {
            textView.text = text
        }
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel(sender:))
        )
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(share(sender:))
        )
    }
    
    @objc
    func cancel(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    func share(sender: UIBarButtonItem) {
        let activityVC = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        
        self.present(activityVC, animated: true, completion: nil)
    }

}

extension DecryptedMessageViewController: UIActivityItemSource {
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        if let message = message {
            return message
        } else {
            return ""
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if let message = message {
            return message
        } else {
            return ""
        }
    }
}
