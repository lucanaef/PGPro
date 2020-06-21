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
    var subtitle: String?
    var type: SettingType

    init(title: String, subtitle: String? = nil, of type: SettingType) {
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }

    // Mark: - Type-specific fields

    // Activity:
    private(set) var activity: ((_ viewController: UIViewController, _ completion: () -> Void) -> ())?
    init(title: String, subtitle: String? = nil, withActivity activity: @escaping (_ viewController: UIViewController, _ completion: () -> Void) -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.type = .Activity
        self.activity = activity
    }

    // Action:
    private(set) var action: (() -> Void)?
    init(title: String, subtitle: String? = nil, actionType: ActionType = .normal, withAction action: @escaping () -> Void) {
        self.title = title
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

    init(title: String, subtitle: String? = nil, forKey key: String, enabled: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.type = .Preference
        self.userDefaultsKey = key
        self.enabled = enabled
    }

    // Link:
    private(set) var url: URL?
    init(title: String, subtitle: String? = nil, withURL url: URL) {
        self.title = title
        self.subtitle = subtitle
        self.type = .Link
        self.url = url
    }

    // Segue:
    private(set) var viewController: UIViewController?
    init(title: String, subtitle: String? = nil, to viewController: UIViewController) {
        self.title = title
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

    private(set) var allSettings: [SettingsDictKey : Setting] = [:]
    init () {
        allSettings[SettingsDictKey(.export,        ExportSection.exportKeychain.rawValue)]         = exportKeychain
        allSettings[SettingsDictKey(.preferences,   PreferencesSection.mailIntegration.rawValue)]   = mailIntegration
        // TODO:
        // allSettings[SettingsDictKey(.preferences,   PreferencesSection.attachPublicKey.rawValue)]   = attachPublicKey
        allSettings[SettingsDictKey(.feedback,      FeedbackSection.sendFeedback.rawValue)]         = sendFeedback
        allSettings[SettingsDictKey(.feedback,      FeedbackSection.askForRating.rawValue)]         = askForRating
        allSettings[SettingsDictKey(.about,         AboutSection.contribute.rawValue)]              = contribute
        allSettings[SettingsDictKey(.about,         AboutSection.privacyPolicy.rawValue)]           = privacyPolicy
        allSettings[SettingsDictKey(.about,         AboutSection.licenses.rawValue)]                = licenses
        allSettings[SettingsDictKey(.actions,       ActionSection.deleteAllKeys.rawValue)]          = deleteAllKeys
    }

    // Mark: - Sections
    enum Sections: Int, CaseIterable {
        case export = 0
        case preferences = 1
        case feedback = 2
        case about = 3
        case actions = 4

        var rows: Int {
            switch self {
                case .export:       return ExportSection.allCases.count
                case .preferences:  return PreferencesSection.allCases.count
                case .feedback:     return FeedbackSection.allCases.count
                case .about:        return AboutSection.allCases.count
                case .actions:      return ActionSection.allCases.count
            }
        }

        var header: String? {
            switch self {
                case .export:       return ExportSection.header
                case .preferences:  return PreferencesSection.header
                case .feedback:     return FeedbackSection.header
                case .about:        return AboutSection.header
                case .actions:      return ActionSection.header
            }
        }
    }

    // MARK: - Subsection
    enum ExportSection: Int, CaseIterable {
        case exportKeychain = 0

        static var header: String? {
            return nil
        }
    }

    enum PreferencesSection: Int, CaseIterable {
        case mailIntegration = 0
        //case attachPublicKey = 1

        static var header: String? {
            return "Preferences"
        }
    }

    enum FeedbackSection: Int, CaseIterable {
        case sendFeedback = 0
        case askForRating = 1

        static var header: String? {
            return "Feedback"
        }
    }

    enum AboutSection: Int, CaseIterable {
        case contribute = 0
        case privacyPolicy = 1
        case licenses = 2

        static var header: String? {
            return "About"
        }
    }

    enum ActionSection: Int, CaseIterable {
        case deleteAllKeys = 0

        static var header: String? {
            return nil
        }
    }

    // Mark: - Actual Settings
    let exportKeychain = Setting(title: "Export Keychain") { viewController, completion in

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
                        try keyring.export().write(to: fileURL)
                    } catch {
                        Log.e("Export failed!")
                        viewController.alert(text: "Export failed!")
                        return
                    }
                    var filesToShare: [Any] = [fileURL]
                    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                    viewController.present(activityViewController, animated: true, completion: nil)
                } else {
                    viewController.alert(text: "Export failed!")
                }
            }
        }
        completion()
    }
    let mailIntegration = Setting(title: "Mail Integration", forKey: Constants.UserDefaultsKeys.mailIntegration, enabled: Constants.User.canSendMail)
    let attachPublicKey = Setting(title: "Attach Public Key", forKey: Constants.UserDefaultsKeys.attachPublicKey, enabled: Constants.User.canSendMail)
    let sendFeedback = Setting(title: "Send Feedback",
                                      withURL: URL(string: "mailto:dev@pgpro.app?subject=%5BPGPro%20\(Constants.PGPro.version ?? "")%5D%20Feedback")!)
    let askForRating = Setting(title: "Please Rate PGPro",
                                      subtitle: "\(Constants.PGPro.numRatings) PEOPLE HAVE RATED THIS VERSION",
                                      withURL: URL(string: "https://itunes.apple.com/app/id\(Constants.PGPro.appID)?action=write-review")!)
    let contribute = Setting(title: "Contribute on GitHub", withURL: URL(string: "https://github.com/lucanaef/PGPro")!)
    let privacyPolicy = Setting(title: "Privacy Policy", withURL: URL(string: "https://pgpro.app/privacypolicy/")!)
    let licenses = Setting(title: "Licenses", to: LicensesViewController())
    let deleteAllKeys = Setting(title: "Delete All Keys", actionType: Setting.ActionType.destructive) {
        ContactListService.deleteAllData()
    }

}
