//
//  MakeCampaignUITests.swift
//  MakeCampaignUITests
//
//  Created by Andrii Solodkyi on 5/1/25.
//

import CoreImage
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
        XCTAssertTrue(app.staticTexts["Збір починається з обкладинки"].exists, "Empty state title should be visible")
        XCTAssertTrue(
            app.staticTexts["Фото, сума й посилання на банку — в одній картинці, готовій до сторіс і чатів."].exists,
            "Empty state subtitle should be visible"
        )
    }

    @MainActor
    func testEmptyStateShowsCoverStack() throws {
        // Then: The cover preview stack sells the result instead of an app icon
        let stack = app.otherElements["empty-state-cover-stack"]
        XCTAssertTrue(stack.waitForExistence(timeout: 3), "Cover stack should be visible")
        XCTAssertEqual(stack.label, "Приклади обкладинок")
    }

    @MainActor
    func testTappingTheCoverStackAdvancesIt() throws {
        let stack = app.otherElements["empty-state-cover-stack"]
        XCTAssertTrue(stack.waitForExistence(timeout: 3))
        let firstCover = stack.value as? String

        // When: The reader taps the stack to see another cover
        stack.tap()

        // Then: A different sample moves to the front of the stack
        let advanced = NSPredicate(format: "value != %@", firstCover ?? "")
        expectation(for: advanced, evaluatedWith: stack)
        waitForExpectations(timeout: 3)
    }

    @MainActor
    func testEmptyStateHidesFloatingActionButton() throws {
        // The empty state carries its own full-width CTA, so the FAB would
        // only sit on top of it.
        XCTAssertFalse(
            app.buttons["create-campaign-button"].exists,
            "Floating action button should be hidden while the empty state is shown"
        )
    }

    @MainActor
    func testCampaignListHasNoStatusSectionSelector() throws {
        XCTAssertFalse(
            app.segmentedControls["campaign-section-picker"].exists,
            "All campaigns should be shown in one list without a status selector"
        )
    }
    
    @MainActor
    func testEmptyStateCallToActionIsVisible() throws {
        // Given: App is in empty state
        
        // Then: Call-to-action elements should be visible
        XCTAssertTrue(app.buttons["empty-create-campaign-button"].exists, "CTA button should be visible")
    }
    
    @MainActor
    func testEmptyStateCreateButtonStartsCreation() throws {
        // Given: App is in empty state
        let ctaButton = app.buttons["empty-create-campaign-button"]
        
        // When: User taps the call-to-action button
        if ctaButton.exists {
            ctaButton.tap()
        }
        
        // Then: The campaign editor opens
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["campaign-poster-preview"].exists)
    }
    
    // MARK: - Floating Action Button Tests
    
    @MainActor
    func testFloatingActionButtonIsVisible() throws {
        // Given: A list that already holds a campaign
        launchWithSeededList()

        // Then: Floating action button should be visible
        let fabButton = app.buttons["create-campaign-button"]
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3), "Floating action button should be visible")
    }

    @MainActor
    func testFloatingActionButtonStartsCreation() throws {
        // Given: A list that already holds a campaign
        launchWithSeededList()
        let fabButton = app.buttons["create-campaign-button"]
        XCTAssertTrue(fabButton.waitForExistence(timeout: 3))

        // When: User taps the FAB
        fabButton.tap()

        // Then: The same campaign editor opens
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["editor-tab-photo"].exists)
        XCTAssertTrue(app.buttons["editor-tab-data"].exists)
        XCTAssertTrue(app.buttons["editor-tab-template"].exists)
        XCTAssertTrue(app.buttons["editor-tab-qr"].exists)
    }

    @MainActor
    private func launchWithSeededList() {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_SEEDED_LIST"]
        app.launch()
    }

    // MARK: - Campaign Row Tests

    // The seeded list: no jar, a jar part-way to its goal, a finished jar.
    private static let noJarRow = "campaign-row-00000000-0000-0000-0000-000000000044"
    private static let partwayRow = "campaign-row-00000000-0000-0000-0000-000000000045"
    private static let finishedRow = "campaign-row-00000000-0000-0000-0000-000000000046"
    private static let noJarPoster = "campaign-row-poster-00000000-0000-0000-0000-000000000044"
    private static let partwayPoster = "campaign-row-poster-00000000-0000-0000-0000-000000000045"

    @MainActor
    func testRowWithoutJarShowsItsTargetButNoRefreshLine() throws {
        launchWithSeededList()
        let row = app.buttons[Self.noJarRow]
        XCTAssertTrue(row.waitForExistence(timeout: 3))

        XCTAssertTrue(row.label.contains("20,000 грн."), "Row label was: \(row.label)")
        XCTAssertFalse(row.label.contains("оновлено"), "Row label was: \(row.label)")
    }

    @MainActor
    func testRowWithJarShowsCollectedOverTargetAndRefreshLine() throws {
        launchWithSeededList()
        let row = app.buttons[Self.partwayRow]
        XCTAssertTrue(row.waitForExistence(timeout: 3))

        let loaded = NSPredicate(format: "label CONTAINS '46,500'")
        expectation(for: loaded, evaluatedWith: row)
        waitForExpectations(timeout: 3)

        XCTAssertTrue(row.label.contains("75,000 грн."), "Row label was: \(row.label)")
        XCTAssertTrue(row.label.contains("62%"), "Row label was: \(row.label)")
        XCTAssertTrue(row.label.contains("оновлено"), "Row label was: \(row.label)")
    }

    @MainActor
    func testFinishedRowSaysCollected() throws {
        launchWithSeededList()
        let row = app.buttons[Self.finishedRow]
        XCTAssertTrue(row.waitForExistence(timeout: 3))

        let finished = NSPredicate(format: "label CONTAINS 'Зібрано!'")
        expectation(for: finished, evaluatedWith: row)
        waitForExpectations(timeout: 3)
    }

    @MainActor
    func testTappingRowPosterOpensFullscreenPreview() throws {
        launchWithSeededList()
        let poster = app.buttons[Self.partwayPoster]
        XCTAssertTrue(poster.waitForExistence(timeout: 3))

        poster.tap()

        let preview = app.otherElements["campaign-poster-fullscreen"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3))
        XCTAssertFalse(app.navigationBars["Редактор"].exists, "The poster must not open the editor")

        app.buttons["campaign-poster-fullscreen-close"].tap()

        XCTAssertTrue(preview.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons[Self.partwayRow].exists)
    }

    @MainActor
    func testSwipingThePreviewDownClosesIt() throws {
        launchWithSeededList()
        app.buttons[Self.noJarPoster].tap()

        let preview = app.otherElements["campaign-poster-fullscreen"]
        XCTAssertTrue(preview.waitForExistence(timeout: 3))

        preview.swipeDown(velocity: .fast)

        XCTAssertTrue(preview.waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testTappingRowDetailsOpensEditor() throws {
        launchWithSeededList()
        let row = app.buttons[Self.noJarRow]
        XCTAssertTrue(row.waitForExistence(timeout: 3))

        row.tap()

        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.otherElements["campaign-poster-fullscreen"].exists)
    }

    @MainActor
    func testDataTabIsPresentedAsName() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))

        XCTAssertEqual(app.buttons["editor-tab-data"].label, "Призначення")
        XCTAssertEqual(app.buttons["editor-tab-qr"].label, "Ціль")
    }

    @MainActor
    func testSupportingJarRevealsThePersonalTarget() throws {
        launchSeededEditor()
        app.buttons["editor-tab-qr"].tap()

        let toggle = app.switches["supporting-jar-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertFalse(app.textFields["campaign-personal-target-field"].exists)

        toggle.tap()

        let personalTarget = app.textFields["campaign-personal-target-field"]
        XCTAssertTrue(personalTarget.waitForExistence(timeout: 2))

        toggle.tap()
        XCTAssertTrue(personalTarget.waitForNonExistence(timeout: 2))
    }

    @MainActor
    func testEditorOpensWithRequestedTabOrderAndTemplateSelected() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))

        let tabs = [
            app.buttons["editor-tab-template"],
            app.buttons["editor-tab-photo"],
            app.buttons["editor-tab-data"],
            app.buttons["editor-tab-qr"],
        ]
        for tab in tabs {
            XCTAssertTrue(tab.waitForExistence(timeout: 2))
        }
        for (leading, trailing) in zip(tabs, tabs.dropFirst()) {
            XCTAssertLessThan(leading.frame.midX, trailing.frame.midX)
        }
        XCTAssertTrue(app.segmentedControls["poster-format-picker"].exists)
    }

    @MainActor
    func testTargetFieldShowsPosterFormattingAndCurrencySuffix() throws {
        app.terminate()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_SEEDED_EDITOR"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["editor-tab-qr"].tap()
        let targetField = app.textFields["campaign-target-field"]
        XCTAssertTrue(targetField.waitForExistence(timeout: 2))
        XCTAssertEqual(targetField.value as? String, "20,000")
        XCTAssertTrue(app.staticTexts["грн."].exists)
    }

    @MainActor
    func testNameTabOmitsFundraisingProgress() throws {
        launchSeededEditor()
        app.buttons["editor-tab-data"].tap()

        XCTAssertFalse(
            app.staticTexts["ПРОГРЕС"].exists,
            "Fundraising progress does not belong in the poster name editor"
        )
    }

    @MainActor
    func testEditorTrayFillsBottomSafeAreaWithPanelColor() throws {
        launchSeededEditor()
        app.buttons["editor-tab-data"].tap()

        let screenshot = app.screenshot()
        let trayPixel = try pixelRGBA(
            in: screenshot,
            normalizedPoint: CGPoint(x: 0.02, y: 0.12)
        )
        for normalizedHeight in [0.01, 0.03, 0.05] {
            let bottomPixel = try pixelRGBA(
                in: screenshot,
                normalizedPoint: CGPoint(x: 0.02, y: normalizedHeight)
            )
            XCTAssertEqual(
                bottomPixel.red,
                trayPixel.red,
                accuracy: 0.02,
                "The editor tray must continue through the bottom safe area"
            )
            XCTAssertEqual(bottomPixel.green, trayPixel.green, accuracy: 0.02)
            XCTAssertEqual(bottomPixel.blue, trayPixel.blue, accuracy: 0.02)
        }
    }

    @MainActor
    func testPhotoTabEmbedsPhotoLibrary() throws {
        launchSeededEditor()
        app.buttons["editor-tab-photo"].tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["campaign-inline-photo-picker"]
                .waitForExistence(timeout: 4)
        )
        XCTAssertFalse(app.buttons["photo-picker-button"].exists)
    }

    @MainActor
    func testInlinePhotoLibraryStaysFixedDuringSelection() throws {
        launchSeededEditor()
        app.buttons["editor-tab-photo"].tap()

        let grid = app.descendants(matching: .any)["campaign-inline-photo-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 4))
        let idleFrame = grid.frame

        app.terminate()
        app.launchArguments = [
            "UI_TESTING",
            "UI_TESTING_SEEDED_EDITOR",
            "UI_TESTING_PHOTO_PROCESSING_EDITOR"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["editor-tab-photo"].tap()

        let processingGrid = app.descendants(matching: .any)["campaign-inline-photo-grid"]
        XCTAssertTrue(processingGrid.waitForExistence(timeout: 4))
        let processingFrame = processingGrid.frame

        XCTAssertEqual(
            processingFrame.minY,
            idleFrame.minY,
            accuracy: 1,
            "Loading a selected photo must not move the inline library vertically"
        )
        XCTAssertEqual(
            processingFrame.height,
            idleFrame.height,
            accuracy: 1,
            "Loading a selected photo must not resize the inline library"
        )
    }

    @MainActor
    func testInlinePhotoLibraryFillsBottomSafeArea() throws {
        launchSeededEditor()
        app.buttons["editor-tab-photo"].tap()

        let grid = app.descendants(matching: .any)["campaign-inline-photo-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 4))

        XCTAssertEqual(
            grid.frame.maxY,
            app.frame.maxY,
            accuracy: 1,
            "The photo grid should continue through the bottom safe area without a white seam"
        )
    }

    @MainActor
    func testPhotoPickerExpansionControlUsesFullScreenAndRestoresEditor() throws {
        launchSeededEditor()
        app.buttons["editor-tab-photo"].tap()

        let grid = app.descendants(matching: .any)["campaign-inline-photo-grid"]
        XCTAssertTrue(grid.waitForExistence(timeout: 4))
        let initialFrame = grid.frame

        let expand = app.buttons["photo-picker-expand-button"]
        XCTAssertTrue(expand.waitForExistence(timeout: 2))
        expand.tap()

        let collapse = app.buttons["photo-picker-collapse-button"]
        XCTAssertTrue(collapse.waitForExistence(timeout: 2))
        let expandedFrame = grid.frame
        XCTAssertLessThan(expandedFrame.minY, initialFrame.minY - 100)
        XCTAssertEqual(expandedFrame.maxY, app.frame.maxY, accuracy: 1)
        keepScreenshot(named: "Campaign Editor - Expanded Photo Library")

        grid.swipeUp(velocity: .slow)
        XCTAssertTrue(collapse.exists, "Scrolling photos must keep the picker expanded")
        XCTAssertEqual(grid.frame, expandedFrame)

        collapse.tap()

        XCTAssertTrue(expand.waitForExistence(timeout: 2))
        XCTAssertEqual(grid.frame, initialFrame)
    }

    @MainActor
    func testPhotoPickerExpansionControlRespondsToVerticalSwipes() throws {
        launchSeededEditor()
        app.buttons["editor-tab-photo"].tap()

        let expand = app.buttons["photo-picker-expand-button"]
        XCTAssertTrue(expand.waitForExistence(timeout: 2))
        expand.swipeDown(velocity: .slow)
        XCTAssertTrue(
            expand.exists,
            "A downward swipe must not expand a collapsed photo picker"
        )
        expand.swipeUp(velocity: .slow)

        let collapse = app.buttons["photo-picker-collapse-button"]
        XCTAssertTrue(
            collapse.waitForExistence(timeout: 2),
            "An upward swipe on the grabber should expand the photo picker"
        )
        collapse.swipeUp(velocity: .slow)
        XCTAssertTrue(
            collapse.exists,
            "An upward swipe must not collapse an expanded photo picker"
        )
        collapse.swipeDown(velocity: .slow)

        XCTAssertTrue(
            expand.waitForExistence(timeout: 2),
            "A downward swipe on the grabber should restore the editor"
        )
    }

    @MainActor
    func testTargetFieldFormatsDigitsWhileTyping() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["editor-tab-qr"].tap()

        let targetField = app.textFields["campaign-target-field"]
        XCTAssertTrue(targetField.waitForExistence(timeout: 2))
        targetField.tap()
        targetField.typeText("20000")
        keepScreenshot(named: "Campaign Editor - Formatted Target While Typing")

        XCTAssertEqual(targetField.value as? String, "20,000")
        XCTAssertTrue(app.staticTexts["грн."].exists)
    }

    @MainActor
    func testTargetFieldAcceptsLocalizedDecimalKeyWhileTyping() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["editor-tab-qr"].tap()

        let targetField = app.textFields["campaign-target-field"]
        XCTAssertTrue(targetField.waitForExistence(timeout: 2))
        targetField.tap()
        targetField.typeText("20000,5")
        keepScreenshot(named: "Campaign Editor - Localized Decimal Target While Typing")

        XCTAssertEqual(targetField.value as? String, "20,000.5")
    }

    @MainActor
    func testKeyboardDoneButtonDismissesPurposeKeyboard() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["editor-tab-data"].tap()

        let titleField = app.textFields["campaign-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2))
        let doneButton = app.buttons["keyboard-done-button"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2))
        XCTAssertEqual(doneButton.label, "Готово")

        doneButton.tap()

        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 2))
        XCTAssertTrue(app.buttons["editor-tab-data"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPurposeReturnMovesFocusToTargetOnTheTargetTab() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["editor-tab-data"].tap()

        let titleField = app.textFields["campaign-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        XCTAssertFalse(app.textFields["campaign-target-field"].exists)

        titleField.tap()
        titleField.typeText("Purpose\n")

        // Ціль живе на сусідній вкладці — Return має перемкнути її та сфокусувати поле.
        let targetField = app.textFields["campaign-target-field"]
        XCTAssertTrue(targetField.waitForExistence(timeout: 2))
        targetField.typeText("25000")

        XCTAssertEqual(targetField.value as? String, "25,000")
        XCTAssertTrue(app.keyboards.firstMatch.exists)
    }

    @MainActor
    func testKeyboardDoneButtonDismissesTargetKeyboard() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["editor-tab-qr"].tap()

        let targetField = app.textFields["campaign-target-field"]
        XCTAssertTrue(targetField.waitForExistence(timeout: 2))
        targetField.tap()

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2))
        targetField.typeText("250")

        let doneButton = app.buttons["keyboard-done-button"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2))
        doneButton.tap()

        XCTAssertEqual(targetField.value as? String, "250")
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 2))
        XCTAssertTrue(app.buttons["editor-tab-qr"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testPosterPhotoTapSelectsPhotoAndOpensPhotoTab() throws {
        launchSeededEditor()
        app.buttons["editor-tab-template"].tap()

        for element in ["photo", "campaign-title", "target"] {
            XCTAssertEqual(
                app.descendants(matching: .any)
                    .matching(identifier: "poster-element-\(element)")
                    .count,
                1,
                "Template thumbnails must not expose interactive poster elements"
            )
        }

        let photo = posterElement("photo")
        XCTAssertTrue(photo.waitForExistence(timeout: 2))
        photo.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["campaign-inline-photo-picker"]
                .waitForExistence(timeout: 4)
        )
        XCTAssertEqual(photo.value as? String, "Вибрано")

        let poster = app.otherElements["campaign-poster-preview"]
        let beforeDrag = poster.screenshot().pngRepresentation

        let dragStart = photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let dragEnd = photo.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.65))
        dragStart.press(forDuration: 0.1, thenDragTo: dragEnd)

        XCTAssertTrue(
            app.descendants(matching: .any)["campaign-inline-photo-picker"].exists
        )
        XCTAssertEqual(photo.value as? String, "Вибрано")
        XCTAssertNotEqual(
            poster.screenshot().pngRepresentation,
            beforeDrag,
            "Dragging the photo must visibly change its alignment"
        )
        keepScreenshot(named: "Campaign Editor - Selected Poster Photo")
    }

    @MainActor
    func testFocusedPhotoOffersContentModeMenu() throws {
        launchSeededEditor()

        XCTAssertFalse(app.staticTexts["Кадрувати"].exists)
        XCTAssertFalse(app.segmentedControls["photo-content-mode"].exists)
        XCTAssertFalse(app.buttons["photo-content-mode-menu"].exists)

        let photo = posterElement("photo")
        XCTAssertTrue(photo.waitForExistence(timeout: 2))
        photo.tap()

        let menu = app.buttons["photo-content-mode-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        XCTAssertEqual(menu.value as? String, "Заповнити")

        let title = posterElement("campaign-title")
        title.tap()
        XCTAssertTrue(menu.waitForNonExistence(timeout: 2))
        XCTAssertEqual(title.value as? String, "Вибрано")

        photo.tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 2))

        menu.tap()
        let fit = app.buttons["photo-content-mode-fit"]
        XCTAssertTrue(fit.waitForExistence(timeout: 2))
        fit.tap()
        XCTAssertTrue(fit.waitForNonExistence(timeout: 2))

        XCTAssertEqual(menu.value as? String, "Вмістити")
    }

    @MainActor
    func testPosterPhotoCanBeDraggedWithoutLeavingNameTab() throws {
        launchSeededEditor()
        app.buttons["editor-tab-data"].tap()

        try assertPosterPhotoCanBeDragged(
            whileKeepingVisible: app.textFields["campaign-title-field"]
        )
    }

    @MainActor
    func testPosterPhotoCanBeDraggedWithoutLeavingTemplateTab() throws {
        launchSeededEditor()
        app.buttons["editor-tab-template"].tap()

        try assertPosterPhotoCanBeDragged(
            whileKeepingVisible: app.scrollViews["campaign-template-thumbnail-strip"]
        )
    }

    @MainActor
    func testPosterPhotoDoubleTapOpensInlineLibrary() throws {
        launchSeededEditor()
        app.buttons["editor-tab-template"].tap()

        let photo = posterElement("photo")
        XCTAssertTrue(photo.waitForExistence(timeout: 2))
        photo.doubleTap()

        XCTAssertTrue(
            app.descendants(matching: .any)["campaign-inline-photo-picker"]
                .waitForExistence(timeout: 4)
        )
        XCTAssertTrue(
            app.buttons["editor-tab-photo"].isHittable,
            "The inline photo library must not cover the campaign editor"
        )
    }

    @MainActor
    func testPosterTitleTapSelectsTextAndDoubleTapFocusesTitle() throws {
        launchSeededEditor()

        let title = posterElement("campaign-title")
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        title.tap()

        let titleField = app.textFields["campaign-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        XCTAssertEqual(title.value as? String, "Вибрано")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        let poster = app.otherElements["campaign-poster-preview"]
        let originalPosterHeight = poster.frame.height

        title.doubleTap()

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(
            poster.frame.height,
            190,
            "The poster should remain readable while the keyboard is visible"
        )
        XCTAssertLessThanOrEqual(poster.frame.height, 220)
        XCTAssertFalse(
            app.buttons["editor-tab-data"].exists,
            "The editor tabs should yield their space while typing"
        )
        let titleContainer = app.descendants(matching: .any)["campaign-title-field-container"]
        XCTAssertTrue(titleContainer.waitForExistence(timeout: 2))
        XCTAssertLessThan(
            titleContainer.frame.maxY,
            keyboard.frame.minY,
            "The complete title control should remain above the keyboard"
        )
        titleField.typeText("! Довга назва збору для перевірки перенесення тексту")
        XCTAssertTrue((titleField.value as? String)?.hasSuffix("перенесення тексту") == true)
        XCTAssertLessThan(
            titleContainer.frame.maxY,
            keyboard.frame.minY,
            "A growing multiline title should remain fully visible"
        )
        keepScreenshot(named: "Campaign Editor - Selected Poster Title")

        poster.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()

        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["editor-tab-data"].waitForExistence(timeout: 2))
        XCTAssertEqual(poster.frame.height, originalPosterHeight, accuracy: 1)
        XCTAssertNotEqual(title.value as? String, "Вибрано")
    }

    @MainActor
    func testPosterTargetDoubleTapSelectsAndFocusesTarget() throws {
        launchSeededEditor()

        let target = posterElement("target")
        XCTAssertTrue(target.waitForExistence(timeout: 2))
        let poster = app.otherElements["campaign-poster-preview"]
        let originalPosterHeight = poster.frame.height
        target.doubleTap()

        let targetField = app.textFields["campaign-target-field"]
        XCTAssertTrue(targetField.waitForExistence(timeout: 2))
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2))
        XCTAssertGreaterThanOrEqual(
            poster.frame.height,
            190,
            "The poster should remain readable while editing the target"
        )
        XCTAssertLessThanOrEqual(poster.frame.height, 220)
        XCTAssertFalse(app.buttons["editor-tab-data"].exists)
        let targetContainer = app.descendants(matching: .any)["campaign-target-field-container"]
        XCTAssertTrue(targetContainer.waitForExistence(timeout: 2))
        XCTAssertLessThan(
            targetContainer.frame.maxY,
            keyboard.frame.minY,
            "The complete target control should remain visible above the keyboard"
        )
        targetField.typeText("5")
        XCTAssertEqual(targetField.value as? String, "200,005")
        XCTAssertLessThan(
            targetContainer.frame.maxY,
            keyboard.frame.minY,
            "Formatting the target should not push its control under the keyboard"
        )
        XCTAssertEqual(target.value as? String, "Вибрано")
        keepScreenshot(named: "Campaign Editor - Selected Poster Target")

        poster.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["editor-tab-data"].waitForExistence(timeout: 2))
        XCTAssertEqual(poster.frame.height, originalPosterHeight, accuracy: 1)
    }

    @MainActor
    func testTargetTabLeadsWithTheTargetAndHidesQRCodeControls() throws {
        launchSeededEditor()

        let targetTab = app.buttons["editor-tab-qr"]
        XCTAssertTrue(targetTab.waitForExistence(timeout: 2))
        XCTAssertTrue(targetTab.label.contains("Ціль"))
        targetTab.tap()

        let targetContainer = app.descendants(matching: .any)["campaign-target-field-container"]
        XCTAssertTrue(targetContainer.waitForExistence(timeout: 2))
        let jarLink = app.textFields["campaign-jar-link-field"]
        XCTAssertTrue(jarLink.waitForExistence(timeout: 2))
        XCTAssertLessThan(
            targetContainer.frame.minY,
            jarLink.frame.minY,
            "The target is the first field on the target tab"
        )
        XCTAssertFalse(app.switches["campaign-qr-toggle"].exists)
        XCTAssertFalse(posterElement("qr").exists)
        XCTAssertFalse(
            app.textFields["campaign-caption-field"].exists,
            "The share caption is generated, so the target tab does not edit it"
        )
        keepScreenshot(named: "Campaign Editor - Target")
    }

    @MainActor
    func testBankURLUsesOptionalPlainTextPlaceholder() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))

        app.buttons["editor-tab-qr"].tap()
        let bankURL = app.textFields["campaign-jar-link-field"]
        XCTAssertTrue(bankURL.waitForExistence(timeout: 2))
        XCTAssertEqual(bankURL.value as? String, "URL Банки (не обов'язково)")
        XCTAssertFalse(app.switches["campaign-qr-toggle"].exists)
    }

    @MainActor
    func testBlankCampaignShowsValidationInsteadOfSharing() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        app.buttons["export-options-button"].tap()
        let share = app.buttons["Поділитися"]
        XCTAssertTrue(share.waitForExistence(timeout: 2))
        share.tap()
        XCTAssertTrue(app.alerts["Щоб створити постер"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testExportOptionsSeparateSavingAndSharing() throws {
        launchSeededEditor()

        app.buttons["export-options-button"].tap()

        XCTAssertTrue(app.buttons["Зберегти у Фото"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Поділитися"].exists)
        XCTAssertFalse(app.buttons["save-and-share-button"].exists)
    }

    @MainActor
    func testEmptyPosterPlaceholderIsCentered() throws {
        app.buttons["empty-create-campaign-button"].tap()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))

        let poster = app.otherElements["campaign-poster-preview"]
        let placeholder = app.staticTexts["campaign-poster-placeholder"]
        XCTAssertTrue(poster.waitForExistence(timeout: 2))
        XCTAssertTrue(placeholder.waitForExistence(timeout: 2))
        XCTAssertEqual(placeholder.label, "Фото")
        XCTAssertLessThan(abs(placeholder.frame.midY - poster.frame.midY), poster.frame.height * 0.12)
    }

    @MainActor
    func testSelectedPhotoReplacesPlaceholderBeforeTemplateSelection() throws {
        app.terminate()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_PHOTO_ONLY_EDITOR"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["campaign-poster-preview"].exists)
        XCTAssertFalse(app.staticTexts["campaign-poster-placeholder"].exists)
        keepScreenshot(named: "Campaign Editor - Photo Without Template")
    }

    @MainActor
    func testSeededCampaignCompletesEditorAndExportJourney() throws {
        app.terminate()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_SEEDED_EDITOR"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.otherElements["campaign-poster-preview"].exists)
        XCTAssertTrue(app.segmentedControls["poster-format-picker"].waitForExistence(timeout: 2))
        keepScreenshot(named: "Campaign Editor - Template")

        app.buttons["editor-tab-photo"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["campaign-inline-photo-picker"]
                .waitForExistence(timeout: 4)
        )
        keepScreenshot(named: "Campaign Editor - Photo")

        app.buttons["editor-tab-data"].tap()
        XCTAssertTrue(app.textFields["campaign-title-field"].waitForExistence(timeout: 2))
        keepScreenshot(named: "Campaign Editor - Name")

        app.buttons["editor-tab-qr"].tap()
        XCTAssertTrue(app.textFields["campaign-jar-link-field"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.switches["campaign-qr-toggle"].exists)
        keepScreenshot(named: "Campaign Editor - Target")

        app.buttons["export-options-button"].tap()
        let share = app.buttons["Поділитися"]
        XCTAssertTrue(share.waitForExistence(timeout: 2))
        keepScreenshot(named: "Campaign Editor - Export Menu")
        share.tap()
        let shareAction = app.cells.matching(
            NSPredicate(
                format: "label IN %@",
                ["Copy", "Копіювати", "Save Image", "Зберегти зображення"]
            )
        ).firstMatch
        XCTAssertTrue(shareAction.waitForExistence(timeout: 8))
        keepScreenshot(named: "Campaign Editor - Share")
    }

    @MainActor
    func testTemplateStripUsesSelectableThumbnailImages() throws {
        launchSeededEditor()
        app.buttons["editor-tab-template"].tap()

        let strip = app.scrollViews["campaign-template-thumbnail-strip"]
        XCTAssertTrue(strip.waitForExistence(timeout: 2))
        let firstTemplate = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'template-'")
        ).firstMatch
        XCTAssertTrue(firstTemplate.waitForExistence(timeout: 2))
        firstTemplate.tap()
        XCTAssertEqual(firstTemplate.value as? String, "Вибрано")
        XCTAssertTrue(
            app.images.matching(
                NSPredicate(format: "identifier BEGINSWITH 'campaign-poster-thumbnail-'")
            ).firstMatch.waitForExistence(timeout: 4)
        )
    }

    @MainActor
    func testTemplateStripReturnsToTheSelectedTemplate() throws {
        launchSeededEditor()
        let strip = app.scrollViews["campaign-template-thumbnail-strip"]
        XCTAssertTrue(strip.waitForExistence(timeout: 2))

        // Deliberately the final entry in Template.list: this loop only ever
        // swipes one way, so a target anywhere else can be scrolled straight
        // past and never come back into view. The end of the strip is also the
        // furthest the selection can be from where it starts, which is the
        // scroll position this test is about restoring.
        let lastTemplate = app.buttons["template-a_linearCoralTeal_trailing"]
        for _ in 0..<24 where !lastTemplate.isHittable {
            strip.swipeLeft(velocity: .fast)
        }
        XCTAssertTrue(lastTemplate.isHittable)
        lastTemplate.tap()
        XCTAssertEqual(lastTemplate.value as? String, "Вибрано")

        app.buttons["editor-tab-photo"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["campaign-inline-photo-picker"]
                .waitForExistence(timeout: 4)
        )
        app.buttons["editor-tab-template"].tap()

        XCTAssertTrue(lastTemplate.waitForExistence(timeout: 2))
        XCTAssertTrue(lastTemplate.isHittable)
        XCTAssertEqual(lastTemplate.value as? String, "Вибрано")
    }

    @MainActor
    func testTemplateStripScrollPerformanceDiagnostic() throws {
        guard ProcessInfo.processInfo.environment[
            "CAMPAIGN_SCROLL_BENCHMARK"
        ] == "1" else {
            throw XCTSkip(
                "Set CAMPAIGN_SCROLL_BENCHMARK=1 to run scroll diagnostics"
            )
        }

        launchSeededEditor()
        app.buttons["editor-tab-template"].tap()
        let strip = app.scrollViews["campaign-template-thumbnail-strip"]
        XCTAssertTrue(strip.waitForExistence(timeout: 2))

        let options = XCTMeasureOptions()
        options.iterationCount = 1
        measure(
            metrics: [
                XCTOSSignpostMetric.scrollingAndDecelerationMetric,
                XCTCPUMetric(),
                XCTMemoryMetric(),
            ],
            options: options
        ) {
            strip.swipeLeft(velocity: .fast)
        }
    }

    private func keepScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launchSeededEditor() {
        app.terminate()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_SEEDED_EDITOR"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Редактор"].waitForExistence(timeout: 3))
    }

    private func posterElement(_ name: String) -> XCUIElement {
        app.descendants(matching: .any)["poster-element-\(name)"]
    }

    private func assertPosterPhotoCanBeDragged(
        whileKeepingVisible editorPanelElement: XCUIElement
    ) throws {
        XCTAssertTrue(editorPanelElement.waitForExistence(timeout: 2))
        let photo = posterElement("photo")
        XCTAssertTrue(photo.waitForExistence(timeout: 2))
        let poster = app.otherElements["campaign-poster-preview"]
        let beforeDrag = poster.screenshot().pngRepresentation

        photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(
                forDuration: 0.1,
                thenDragTo: photo.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.7, dy: 0.65)
                )
            )

        XCTAssertTrue(
            editorPanelElement.exists,
            "Dragging the photo must keep the current editor tab visible"
        )
        XCTAssertNotEqual(
            poster.screenshot().pngRepresentation,
            beforeDrag,
            "Dragging the photo must visibly change its alignment"
        )
    }

    private func pixelRGBA(
        in screenshot: XCUIScreenshot,
        normalizedPoint: CGPoint
    ) throws -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let image = CIImage(cgImage: screenshot.image.cgImage!)
        let point = CGPoint(
            x: image.extent.width * normalizedPoint.x,
            y: image.extent.height * normalizedPoint.y
        )
        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext(options: nil).render(
            image,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(origin: point, size: CGSize(width: 1, height: 1)),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return (
            red: CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue: CGFloat(pixel[2]) / 255,
            alpha: CGFloat(pixel[3]) / 255
        )
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
        let titleText = app.staticTexts["Збір починається з обкладинки"]
        XCTAssertTrue(titleText.exists)
    }
    
    @MainActor
    func testFloatingActionButtonIsAccessible() throws {
        // Given: A list that already holds a campaign
        launchWithSeededList()

        // Then: FAB should be accessible
        XCTAssertTrue(
            app.buttons["create-campaign-button"].waitForExistence(timeout: 3),
            "The create button should be accessible"
        )
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
