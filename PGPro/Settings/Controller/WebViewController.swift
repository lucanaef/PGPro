//
//  WebViewController.swift
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
import WebKit

class WebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!

    var urlRequest: URLRequest?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let urlRequest = urlRequest {
            webView.load(urlRequest)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        /* Hide AppLabel & Name from View */
        for subview in self.navigationController!.view.subviews.filter({$0 is UILabel}) {
            subview.isHidden = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        /* Un-hide AppLabel & Name from View */
        if let navigationController = self.navigationController {
            for subview in navigationController.view.subviews.filter({$0 is UILabel}) {
                subview.isHidden = false
            }
        }
    }
}
