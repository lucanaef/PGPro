//
//  FastlaneSnapshot.swift
//  FastlaneSnapshot
//

import XCTest

class FastlaneSnapshot: XCTestCase {

    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGenerateScreenshots() {
        let app = XCUIApplication()
        
        snapshot("1-EncryptionView")
        
        app.tabBars.buttons["Decryption"].tap()
        
        snapshot("2-DecryptionView")
        
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
