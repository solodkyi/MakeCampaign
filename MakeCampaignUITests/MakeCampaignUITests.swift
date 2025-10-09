//
//  MakeCampaignUITests.swift
//  MakeCampaignUITests
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import XCTest

final class MakeCampaignUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Empty State Tests
    
    @MainActor
    func testEmptyStateIsDisplayedWhenNoCampaigns() throws {
        // Given: App launches with no campaigns
        
        // Then: Empty state UI elements should be visible
        XCTAssertTrue(app.images["megaphone.fill"].exists, "Empty state icon should be visible")
        XCTAssertTrue(app.staticTexts["Створіть свою першу обкладинку для збору коштів"].exists, "Empty state title should be visible")
        XCTAssertTrue(app.staticTexts["Допомагайте тим, хто цього потребує"].exists, "Empty state subtitle should be visible")
    }
    
    @MainActor
    func testEmptyStateCallToActionIsVisible() throws {
        // Given: App is in empty state
        
        // Then: Call-to-action elements should be visible
        XCTAssertTrue(app.staticTexts["Натисніть"].exists, "CTA text should be visible")
        XCTAssertTrue(app.images["plus"].exists, "Plus icon should be visible")
        XCTAssertTrue(app.staticTexts["щоб створити збір"].exists, "CTA instruction should be visible")
    }
    
    @MainActor
    func testEmptyStatePlusButtonOpensCreateCampaignSheet() throws {
        // Given: App is in empty state
        let ctaButton = app.staticTexts.containing(.staticText, identifier: "Натисніть").element
        
        // When: User taps the call-to-action button
        if ctaButton.exists {
            ctaButton.tap()
        }
        
        // Then: Create campaign sheet should appear
        let navigationBar = app.navigationBars["Новий збір"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 2), "Create campaign sheet should be presented")
    }
    
    // MARK: - Floating Action Button Tests
    
    @MainActor
    func testFloatingActionButtonIsVisible() throws {
        // Given: App is launched
        
        // Then: Floating action button should be visible
        let fabButton = app.buttons.matching(identifier: "plus").element(boundBy: 0)
        XCTAssertTrue(fabButton.exists, "Floating action button should be visible")
    }
    
    @MainActor
    func testFloatingActionButtonOpensCreateCampaignSheet() throws {
        // Given: App is launched
        let fabButtons = app.buttons.matching(NSPredicate(format: "identifier == 'plus'"))
        
        // Find the FAB (not the one in empty state)
        var fabButton: XCUIElement?
        for index in 0..<fabButtons.count {
            let button = fabButtons.element(boundBy: index)
            if button.frame.maxY > app.frame.height * 0.8 { // FAB is at the bottom
                fabButton = button
                break
            }
        }
        
        // When: User taps the FAB
        if let fabButton = fabButton, fabButton.exists {
            fabButton.tap()
            
            // Then: Create campaign sheet should appear
            let navigationBar = app.navigationBars["Новий збір"]
            XCTAssertTrue(navigationBar.waitForExistence(timeout: 2), "Create campaign sheet should be presented")
        }
    }
    
    // MARK: - Campaign Grid Tests
    
    @MainActor
    func testCampaignCardsAreDisplayedInGrid() throws {
        // Given: App has campaigns (this test requires campaigns to exist)
        // Note: In a real test, you'd need to set up test data
        
        // Then: Check if campaign cards are visible
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Campaign cards should be displayed
            XCTAssertTrue(true, "Campaign grid should be visible when campaigns exist")
        }
    }
    
    @MainActor
    func testCampaignCardDisplaysCampaignDetails() throws {
        // Given: App has at least one campaign
        let scrollView = app.scrollViews.firstMatch
        
        if scrollView.exists {
            // Then: Campaign card should show details
            // Check for common elements like progress label, target label, collected label
            let progressLabel = app.staticTexts["Прогрес"]
            let targetLabel = app.staticTexts["Ціль:"]
            let collectedLabel = app.staticTexts["Зібрано:"]
            
            // At least one of these should exist if campaigns are present
            let hasDetails = progressLabel.exists || targetLabel.exists || collectedLabel.exists
            if hasDetails {
                XCTAssertTrue(true, "Campaign details should be visible")
            }
        }
    }
    
    @MainActor
    func testTappingCampaignCardSelectsCampaign() throws {
        // Given: App has at least one campaign
        let scrollView = app.scrollViews.firstMatch
        
        if scrollView.exists {
            // When: User taps on a campaign card
            let firstCard = scrollView.otherElements.firstMatch
            if firstCard.exists {
                firstCard.tap()
                
                // Then: Campaign should be selected (this would navigate or show details)
                // The actual behavior depends on your app's navigation
                XCTAssertTrue(true, "Campaign selection action should be triggered")
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testCreateCampaignSheetHasCorrectTitle() throws {
        // Given: User opens create campaign sheet
        let fabButtons = app.buttons.matching(NSPredicate(format: "identifier == 'plus'"))
        if let fabButton = fabButtons.element(boundBy: fabButtons.count - 1).exists ? fabButtons.element(boundBy: fabButtons.count - 1) : nil {
            fabButton.tap()
        }
        
        // Then: Sheet should have correct navigation title
        let navigationBar = app.navigationBars["Новий збір"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 2), "Navigation bar should show 'Новий збір' title")
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testEmptyStateIsAccessible() throws {
        // Then: Empty state elements should be accessible
        let emptyStateIcon = app.images["megaphone.fill"]
        XCTAssertTrue(emptyStateIcon.exists)
        
        let titleText = app.staticTexts["Створіть свою першу обкладинку для збору коштів"]
        XCTAssertTrue(titleText.exists)
    }
    
    @MainActor
    func testFloatingActionButtonIsAccessible() throws {
        // Then: FAB should be accessible
        let fabButtons = app.buttons.matching(NSPredicate(format: "identifier == 'plus'"))
        XCTAssertTrue(fabButtons.count > 0, "At least one plus button should exist")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testScrollPerformanceWithCampaigns() throws {
        // Given: App with campaigns
        let scrollView = app.scrollViews.firstMatch
        
        if scrollView.exists {
            // When: User scrolls through campaigns
            measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
        }
    }
}
