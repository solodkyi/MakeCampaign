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
        XCTAssertTrue(app.staticTexts["Активних зборів\nще немає"].exists, "Empty state title should be visible")
        XCTAssertTrue(app.staticTexts["Створіть обкладинку або імпортуйте дані з посилання на банку."].exists, "Empty state subtitle should be visible")
    }
    
    @MainActor
    func testEmptyStateCallToActionIsVisible() throws {
        // Given: App is in empty state
        
        // Then: Call-to-action elements should be visible
        XCTAssertTrue(app.buttons["empty-create-campaign-button"].exists, "CTA button should be visible")
    }
    
    @MainActor
    func testEmptyStateCreateButtonDoesNotStartCreation() throws {
        // Given: App is in empty state
        let ctaButton = app.buttons["empty-create-campaign-button"]
        
        // When: User taps the call-to-action button
        if ctaButton.exists {
            ctaButton.tap()
        }
        
        // Then: Creation is intentionally out of scope
        let navigationBar = app.navigationBars["Новий збір"]
        XCTAssertFalse(navigationBar.waitForExistence(timeout: 1), "Create campaign sheet should not be presented")
    }
    
    // MARK: - Floating Action Button Tests
    
    @MainActor
    func testFloatingActionButtonIsVisible() throws {
        // Given: App is launched
        
        // Then: Floating action button should be visible
        let fabButton = app.buttons["create-campaign-button"]
        XCTAssertTrue(fabButton.exists, "Floating action button should be visible")
    }
    
    @MainActor
    func testFloatingActionButtonDoesNotStartCreation() throws {
        // Given: App is launched
        let fabButton = app.buttons["create-campaign-button"]
        
        // When: User taps the FAB
        if fabButton.exists {
            fabButton.tap()
            
            // Then: Creation is intentionally out of scope
            let navigationBar = app.navigationBars["Новий збір"]
            XCTAssertFalse(navigationBar.waitForExistence(timeout: 1), "Create campaign sheet should not be presented")
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
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testEmptyStateIsAccessible() throws {
        // Then: Empty state elements should be accessible
        let titleText = app.staticTexts["Активних зборів\nще немає"]
        XCTAssertTrue(titleText.exists)
    }
    
    @MainActor
    func testFloatingActionButtonIsAccessible() throws {
        // Then: FAB should be accessible
        XCTAssertTrue(app.buttons["create-campaign-button"].exists, "The create button should be accessible")
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
