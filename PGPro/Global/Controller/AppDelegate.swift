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

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.tintColor = .label

        // Handle (first) Application Launch
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: Preferences.UserDefaultsKeys.launchedBefore)
        if !hasLaunchedBefore {
            firstLaunch()
        } else {
            if Preferences.biometricAuthentication {
                let authController = AuthenticationViewController()
                window?.rootViewController = authController
                window?.makeKeyAndVisible()
                authController.authenticatedLaunch()
            } else {
                launch()
            }
        }

        return true
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // Check if file type is supported
        guard url.pathExtension == "asc" else { return false }

        // Load file contents
        var fileContants: String?
        do {
            fileContants = try String(contentsOf: url, encoding: .ascii)
        } catch {
            Log.e("Filetype not supported!")
            return false
        }
        if let fileContants = fileContants {
            if fileContants.contains("KEY BLOCK") {
                // Treat content as key
                var readKeys = [Key]()
                do {
                    readKeys = try KeyConstructionService.fromString(keyString: fileContants)
                } catch {
                    Log.e("No key found in file!")
                    return true
                }
                let result: ContactListResult = ContactListService.importFrom(readKeys)

                /* Present result if application is unlocked */
                if !Preferences.biometricAuthentication {
                    DispatchQueue.main.async {
                        let actualVC = self.window?.rootViewController?.children[1].children.first
                        while !(actualVC is DecryptionViewController) { }
                        let decryptionVC = actualVC as? DecryptionViewController

                        if let decryptionVC = decryptionVC {
                            while decryptionVC.viewIfLoaded == nil {  }
                            decryptionVC.alert(result)
                        }
                    }
                }
                return true
            } else if fileContants.contains("MESSAGE") {
                decryptionVC.setMessageField(to: fileContants)
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    func applicationWillResignActive(_ application: UIApplication) { }

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // I don't want to authenticate every time the app becomes active since it resets the UI state every time
        //  this means copying text from other apps would become very difficult and I don't want to keep track of
        //  the state myself.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        PersistenceService.save()
    }

    // MARK: - Helper functions

    private func buildTabBarController() -> UITabBarController {

        let tabBarController = UITabBarController()
        let viewControllers = [encryptionVC, decryptionVC, keychainVC, settingsVC]
        let navigationViewControllers = viewControllers.map { UINavigationController.init(rootViewController: $0) }
        tabBarController.viewControllers = navigationViewControllers

        let encryptionTabImage = UIImage(systemName: "lock.fill")
        let encryptionTab = UITabBarItem(title: "Encryption", image: encryptionTabImage, selectedImage: encryptionTabImage)
        navigationViewControllers[0].tabBarItem = encryptionTab
        navigationViewControllers[0].navigationBar.prefersLargeTitles = true

        let decryptionTabImage = UIImage(systemName: "lock.open.fill")
        let decryptionTab = UITabBarItem(title: "Decryption", image: decryptionTabImage, selectedImage: decryptionTabImage)
        navigationViewControllers[1].tabBarItem = decryptionTab
        navigationViewControllers[1].navigationBar.prefersLargeTitles = true

        let keychainTabImage = UIImage(systemName: "person.2.fill")
        let keychainTab = UITabBarItem(title: "Keychain", image: keychainTabImage, selectedImage: keychainTabImage)
        navigationViewControllers[2].tabBarItem = keychainTab
        navigationViewControllers[2].navigationBar.prefersLargeTitles = true

        let settingsTabImage = UIImage(systemName: "gear")
        let settingsTab = UITabBarItem(title: "Settings", image: settingsTabImage, selectedImage: settingsTabImage)
        navigationViewControllers[3].tabBarItem = settingsTab
        navigationViewControllers[3].navigationBar.prefersLargeTitles = true

        // Select "Decrypt Message"-View as first view
        tabBarController.selectedIndex = 1

        return tabBarController
    }

    private func firstLaunch() {
        // If in simulator, create example dataset
        #if targetEnvironment(simulator)
            ExampleDataService.createExampleDataset()
        #endif

        // Set default preferences
        Preferences.setToDefault()

        // Get number of ratings (warm up cache)
        _ = Constants.PGPro.numRatings

        self.window?.rootViewController = self.buildTabBarController()
        self.window?.makeKeyAndVisible()
    }

    func launch() {
        ContactListService.loadPersistentData()

        self.window?.rootViewController = self.buildTabBarController()
        self.window?.makeKeyAndVisible()
    }

}
