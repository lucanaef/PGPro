//
//  AppDelegate.swift
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
import CoreData
import ObjectivePGP

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let encryptionVC = EncryptionViewController()
    let decryptionVC = DecryptionViewController()
    let keychainVC = KeychainViewController()
    let settingsVC = SettingsViewController()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Setup Tab View Controller
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = buildTabBarController()
        window?.tintColor = .label
        window?.makeKeyAndVisible()

        // Handle Application launch
        let launchedBefore = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.launchedBefore)
        if !launchedBefore {

            // If in simulator, create example dataset
            #if targetEnvironment(simulator)
                ExampleDataService.createExampleDataset()
            #endif

            // Set default preferences
            Preferences.setToDefault()

            // Get number of ratings (warm up cache)
            _ = Constants.PGPro.numRatings
        } else {
            ContactListService.loadPersistentData()

            // Check if device currently can send mail
            if (!Constants.User.canSendMail) {
                UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.mailIntegration)
                UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.attachPublicKey)
            }
        }

        return true
    }

    private func buildTabBarController() -> UITabBarController {

        let tabBarController = UITabBarController()
        let viewControllers = [encryptionVC, decryptionVC, keychainVC, settingsVC]
        let navigationViewControllers = viewControllers.map{ UINavigationController.init(rootViewController: $0)}
        tabBarController.viewControllers = navigationViewControllers

        let encryptionTabTitle = "Encryption"
        let encryptionTabImage = UIImage(systemName: "lock.fill")
        let encryptionTab = UITabBarItem(title: encryptionTabTitle, image: encryptionTabImage, selectedImage: encryptionTabImage)
        navigationViewControllers[0].tabBarItem = encryptionTab

        let decryptionTabTitle = "Decryption"
        let decryptionTabImage = UIImage(systemName: "lock.open.fill")
        let decryptionTab = UITabBarItem(title: decryptionTabTitle, image: decryptionTabImage, selectedImage: decryptionTabImage)
        navigationViewControllers[1].tabBarItem = decryptionTab

        let keychainTabTitle = "Keychain"
        let keychainTabImage = UIImage(systemName: "person.2.fill")
        let keychainTab = UITabBarItem(title: keychainTabTitle, image: keychainTabImage, selectedImage: keychainTabImage)
        navigationViewControllers[2].tabBarItem = keychainTab

        let settingsTabTitle = "Settings"
        let settingsTabImage = UIImage(systemName: "gear")
        let settingsTab = UITabBarItem(title: settingsTabTitle, image: settingsTabImage, selectedImage: settingsTabImage)
        navigationViewControllers[3].tabBarItem = settingsTab

        return tabBarController
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // Check if file type is valid
        let fileExtension = url.pathExtension
        guard (fileExtension == "asc") else {
            let alertController = UIAlertController(title: "Filetype not supported!", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            window?.rootViewController?.present(alertController, animated: true, completion: nil)
            Log.i("Filetype \(fileExtension) not supported!")
            return false
        }

        // Treat file as PGP encrypted text
        var encryptedMessage = ""
        do {
            encryptedMessage = try String(contentsOf: url, encoding: .ascii)
            if let tabBarController = window?.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 1
            }
        } catch {
            let alertController = UIAlertController(title: "File not supported!", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            window?.rootViewController?.present(alertController, animated: true, completion: nil)
            Log.i("File not supported!")
            return false
        }

        DispatchQueue.main.async {
            let actualVC = self.window?.rootViewController?.children[1].children.first
            while !(actualVC is DecryptionViewController) { }
            let decryptionVC = actualVC as? DecryptionViewController
            if let decryptionVC = decryptionVC {
                while (decryptionVC.viewIfLoaded == nil) {  }
                decryptionVC.setMessageField(to: encryptedMessage)
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { }

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) {
        PersistenceService.save()
    }

}
