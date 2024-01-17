//
//  Vw_AugmentedReality_iOSUITestsLaunchTests.swift
//  Vw_AugmentedReality_iOSUITests
//
//  Created by Nahom Ghebredngl on 9/20/23.
//

import XCTest

final class Vw_AugmentedReality_iOSUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
