//
//  AuthenticationViewController.swift
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

class AuthenticationViewController: UIViewController {

    lazy private var lockImageView: UIImageView = {
        let image = UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .light))!
            .withTintColor(.white, renderingMode: .alwaysOriginal)

        let imageView = UIImageView(image: image, highlightedImage: image)
        imageView.sizeToFit()
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    lazy private var authImage: UIImage = {
        return UIImage(systemName: AuthenticationService.symbolName)!.withTintColor(.white)
    }()

    lazy private var authenticateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(" Authenticate", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)

        button.setImage(authImage, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit

        button.tintColor = .black
        button.backgroundColor = .white

        button.layer.cornerRadius = 4
        button.contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)

        button.addTarget(self, action: #selector(self.authenticateAction), for: .touchUpInside)

        return button
    }()

    lazy private var viewStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [lockImageView, authenticateButton])
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.setCustomSpacing(50.0, after: lockImageView)

        return stackView
    }()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .black

        viewStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewStack)
        viewStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        viewStack.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
    }


    @objc
    func authenticateAction(onSuccess: @escaping () -> Void) {
        AuthenticationService.requestAuthentication { result in
            switch result {
            case .failure(let error):
                switch error.code {
                case .userCancel: Log.d("Authentication failed: \(error.localizedDescription)")
                default:
                    DispatchQueue.main.async {
                        self.alert(text: "Authentication failed: \(error.localizedDescription)")
                    }
                }
            case .success(let succ):
                DispatchQueue.main.async {
                    if succ { onSuccess() } else { self.alert(text: "Authentication failed")}
                }
            }
        }
    }

}
