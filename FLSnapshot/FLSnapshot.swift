//
//  FLSnapshot.swift
//  FLSnapshot
//
//  Created by Luca Näf on 10.03.20.
//  Copyright © 2020 Luca Näf. All rights reserved.
//

import XCTest

class FLSnapshot: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGenerateScreenshots() {
        let app = XCUIApplication()

        snapshot("2-DecryptionView")

        app.tabBars.buttons["Encryption"].tap()
        snapshot("1-EncryptionView")

        app.tabBars.buttons["Settings"].tap()
        snapshot("5-SettingsView")

        app.tabBars.buttons["Keychain"].tap()
        snapshot("3-KeychainView")

        app.tables.firstMatch.cells.firstMatch.tap()
        snapshot("4-DetailView")
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
