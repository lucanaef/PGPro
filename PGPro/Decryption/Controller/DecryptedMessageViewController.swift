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

    private var textView: UITextView?
    private var message: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Navigation bar
        self.title = "Decrypted Message"
        let leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel(sender:))
        )
        let rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(share(sender:))
        )
        self.navigationItem.setLeftBarButton(leftBarButtonItem, animated: false)
        self.navigationItem.setRightBarButton(rightBarButtonItem, animated: false)

        // Text view
        textView = UITextView(frame: CGRect(x: 0, y: 56, width: view.frame.size.width, height: view.frame.size.height))
        textView!.font = UIFont.systemFont(ofSize: 18.0)
        textView!.text = message ?? "Test Message"
        textView!.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.addSubview(textView!)
    }

    func show(_ message: String) {
        self.message = message
    }

    @objc
    private func cancel(sender: UIBarButtonItem) {
        // Ask for review after decryption
        let twoSecondsFromNow = DispatchTime.now() + 2.0
        DispatchQueue.main.asyncAfter(deadline: twoSecondsFromNow) {
            AppStoreReviewService.requestReviewIfAppropriate()
        }
        dismiss(animated: true, completion: nil)
        self.message = nil
    }

    @objc
    private func share(sender: UIBarButtonItem) {
        let activityVC = UIActivityViewController(activityItems: [self], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true, completion: nil)
    }

}

extension DecryptedMessageViewController: UIActivityItemSource {

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return message ?? ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return message ?? ""
    }
}
