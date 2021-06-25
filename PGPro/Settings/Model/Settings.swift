//
//  Settings.swift
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
import ObjectivePGP

class Setting {

    // type of setting for the controller to know how to display them
    enum SettingType {
        case Activity
        case Action(type: ActionType)
        case Preference
        case Link
        case Segue
    }

    enum ActionType {
        case normal
        case destructive
    }

    var title: String
    var symbol: UIImage
    var subtitle: String?
    var type: SettingType

    init(title: String, symbol: UIImage, subtitle: String? = nil, of type: SettingType) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.type = type
    }

    // Mark: - Type-specific fields

    // Activity:
    private(set) var activity: ((_ viewController: UIViewController, _ completion: () -> Void) -> Void)?
    init(title: String, symbol: UIImage, subtitle: String? = nil, withActivity activity: @escaping (_ viewController: UIViewController, _ completion: () -> Void) -> Void) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.type = .Activity
        self.activity = activity
    }

    // Action:
    private(set) var action: (() -> Void)?
    init(title: String, symbol: UIImage, subtitle: String? = nil, actionType: ActionType = .normal, withAction action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.type = .Action(type: actionType)
        self.action = action
    }

    // Mark: - Preference
    private var userDefaultsKey: String?
    var enabled: Bool?
    var toggled: Bool? {
        get {
            guard let key = userDefaultsKey else { return false }
            return UserDefaults.standard.bool(forKey: key)
        }
        set {
            guard let key = userDefaultsKey, let newStatus = newValue else { return }
            UserDefaults.standard.set(newStatus, forKey: key)
        }
    }

    init(title: String, symbol: UIImage, subtitle: String? = nil, forKey key: String, enabled: Bool) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.type = .Preference
        self.userDefaultsKey = key
        self.enabled = enabled
    }

    // Link:
    private(set) var url: URL?
    init(title: String, symbol: UIImage, subtitle: String? = nil, withURL url: URL) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.type = .Link
        self.url = url
    }

    // Segue:
    private(set) var viewController: UIViewController?
    init(title: String, symbol: UIImage, subtitle: String? = nil, to viewController: UIViewController) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.type = .Segue
        self.viewController = viewController
    }


}

class Settings {

    struct SettingsDictKey: Hashable {
        var section: Sections
        var subsection: Int

        init (_ section: Sections, _ subsection: Int) {
            self.section = section
            self.subsection = subsection
        }
    }

    private(set) var allSettings: [SettingsDictKey: Setting] = [:]
    init () {
        allSettings[SettingsDictKey(.data,          DataSection.exportKeychain.rawValue)]           = exportKeychain
        allSettings[SettingsDictKey(.data,          DataSection.deleteAllKeys.rawValue)]            = deleteAllKeys
        allSettings[SettingsDictKey(.preferences,   PreferencesSection.mailIntegration.rawValue)]   = mailIntegration
        allSettings[SettingsDictKey(.preferences,   PreferencesSection.authentication.rawValue)]    = authentication
        allSettings[SettingsDictKey(.preferences,   PreferencesSection.yubikey.rawValue)]           = yubikey
        allSettings[SettingsDictKey(.feedback,      FeedbackSection.sendFeedback.rawValue)]         = reportIssue
        allSettings[SettingsDictKey(.feedback,      FeedbackSection.joinBeta.rawValue)]             = joinBeta
        allSettings[SettingsDictKey(.feedback,      FeedbackSection.askForRating.rawValue)]         = askForRating
        allSettings[SettingsDictKey(.about,         AboutSection.faq.rawValue)]                     = faq
        allSettings[SettingsDictKey(.about,         AboutSection.contribute.rawValue)]              = contribute
        allSettings[SettingsDictKey(.about,         AboutSection.privacyPolicy.rawValue)]           = privacyPolicy
        allSettings[SettingsDictKey(.about,         AboutSection.licenses.rawValue)]                = licenses
    }

    // Mark: - Sections
    enum Sections: Int, CaseIterable {
        case data = 0
        case preferences = 1
        case feedback = 2
        case about = 3

        var rows: Int {
            switch self {
            case .data:         return DataSection.allCases.count
            case .preferences:  return PreferencesSection.allCases.count
            case .feedback:     return FeedbackSection.allCases.count
            case .about:        return AboutSection.allCases.count
            }
        }

        var header: String? {
            switch self {
            case .data:         return DataSection.header
            case .preferences:  return PreferencesSection.header
            case .feedback:     return FeedbackSection.header
            case .about:        return AboutSection.header
            }
        }
    }

    // MARK: - Subsection
    enum DataSection: Int, CaseIterable {
        case exportKeychain = 0
        case deleteAllKeys = 1

        static var header: String {
            return "Data"
        }
    }

    enum PreferencesSection: Int, CaseIterable {
        case mailIntegration = 0
        case authentication = 1
        case yubikey = 2

        static var header: String {
            return "Preferences"
        }
    }

    enum FeedbackSection: Int, CaseIterable {
        case sendFeedback = 0
        case joinBeta = 1
        case askForRating = 2

        static var header: String {
            return "Feedback"
        }
    }

    enum AboutSection: Int, CaseIterable {
        case faq = 0
        case contribute = 1
        case privacyPolicy = 2
        case licenses = 3

        static var header: String {
            return "About"
        }
    }


    // Mark: - Actual Settings
    let exportKeychain = Setting(title: "Export Keychain", symbol: UIImage(systemName: "square.and.arrow.up")!) { viewController, completion in
        DispatchQueue.global(qos: .default).async {
            let keyring = Keyring()
            var keys: [Key] = []
            for cntct in ContactListService.get(ofType: .both) {
                keys.append(cntct.key)
            }
            keyring.import(keys: keys)
            DispatchQueue.main.async {
                let file = "keychain.gpg"
                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = dir.appendingPathComponent(file)
                    do {
                        try keyring.export().write(to: fileURL, options: .completeFileProtection)
                    } catch {
                        Log.e("Export failed!")
                        viewController.alert(text: "Export failed!")
                        return
                    }
                    var filesToShare: [Any] = [fileURL]
                    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                    if let popoverController = activityViewController.popoverPresentationController {
                        popoverController.sourceView = viewController.view
                        popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    viewController.present(activityViewController, animated: true, completion: nil)
                } else {
                    viewController.alert(text: "Export failed!")
                }
            }
        }
        completion()
    }
    let deleteAllKeys       = Setting(title: "Delete Keychain",
                                      symbol: UIImage(systemName: "trash")!,
                                      actionType: Setting.ActionType.destructive) {
                                        ContactListService.deleteAllData()
                                      }
    let mailIntegration     = Setting(title: "Mail Integration",
                                      symbol: UIImage(systemName: "envelope")!,
                                      forKey: Preferences.UserDefaultsKeys.mailIntegration,
                                      enabled: Constants.User.canSendMail)
    let authentication      = Setting(title: "App Launch Authentication",
                                      symbol: UIImage(systemName: AuthenticationService.symbolName)!,
                                      forKey: Preferences.UserDefaultsKeys.biometricAuthentication,
                                      enabled: AuthenticationService.supportedByDevice)
    let yubikey             = Setting(title: "Yubikey",
                                      symbol: UIImage(systemName: "key.fill")!,
                                      //symbol: UIImage.resize(image: UIImage(named: "LASKey")!, targetSize: CGSize(width: 8, height: 22)),
                                      forKey: Preferences.UserDefaultsKeys.yubikey,
                                      enabled: Yubikey.supportedByDevice)
    let reportIssue         = Setting(title: "Report Issue",
                                      symbol: UIImage(systemName: "ladybug")!,
                                      withURL: URL(string: "https://github.com/lucanaef/PGPro/issues")!)
    let joinBeta            = Setting(title: "Join the PGPro Beta",
                                      symbol: UIImage(systemName: "airplane")!,
                                      withURL: URL(string: "https://testflight.apple.com/join/BNawuaNF")!)
    let askForRating        = Setting(title: "Please Rate PGPro",
                                      symbol: UIImage(systemName: "heart")!,
                                      subtitle: "\(Constants.PGPro.numRatings) PEOPLE HAVE RATED PGPRO IN YOUR REGION",
                                      withURL: URL(string: "https://itunes.apple.com/app/id\(Constants.PGPro.appID)?action=write-review")!)
    let faq                 = Setting(title: "Frequently Asked Questions",
                                      symbol: UIImage(systemName: "questionmark.circle")!,
                                      withURL: URL(string: "https://pgpro.app/faq/")!)
    let contribute          = Setting(title: "Contribute on GitHub",
                                      symbol: UIImage(systemName: "chevron.left.slash.chevron.right")!,
                                      withURL: URL(string: "https://github.com/lucanaef/PGPro")!)
    let privacyPolicy       = Setting(title: "Privacy Policy",
                                      symbol: UIImage(systemName: "eye.slash")!,
                                      withURL: URL(string: "https://pgpro.app/privacypolicy/")!)
    let licenses            = Setting(title: "Licenses",
                                      symbol: UIImage(systemName: "scroll")!,
                                      to: LicensesViewController())
}
