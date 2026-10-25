import XCTest

@MainActor
final class LifeIsShortUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(seed: Bool = false, language: String = "en", preserve: Bool = false, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(\(language))", "-AppleLocale", language == "ja" ? "ja_JP" : language == "id" ? "id_ID" : "en_US"]
        if seed { app.launchArguments.append("-seed-samples") }
        if preserve { app.launchArguments.append("-preserve-library") }
        app.launchArguments += extra
        app.launch()
        XCTAssertTrue(app.buttons["addMilestone"].waitForExistence(timeout: 15))
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable)
    }

    private func visibility(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.switches.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
    }

    private func row(_ title: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'milestone-' AND label CONTAINS %@", title)).firstMatch
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? app.screenshot().pngRepresentation.write(to: directory.appendingPathComponent(name + ".png"))
    }

    func testCreateOverwriteAndRelaunch() throws {
        var app = launch()
        capture("Empty library", app: app)
        app.buttons["addMilestone"].tap()
        let title = app.textFields["milestoneTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("First milestone")
        app.buttons["saveMilestone"].tap()
        let saved = row("First milestone", in: app)
        reveal(saved, in: app); saved.tap()
        let editorTitle = app.textFields["milestoneTitle"]
        XCTAssertTrue(editorTitle.waitForExistence(timeout: 5))
        editorTitle.tap()
        editorTitle.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "First milestone".count))
        editorTitle.typeText("Updated milestone")
        app.buttons["saveMilestone"].tap()
        XCTAssertTrue(row("Updated milestone", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(row("First milestone", in: app).exists)
        app.terminate()
        app = launch(preserve: true)
        XCTAssertTrue(row("Updated milestone", in: app).waitForExistence(timeout: 5))
        capture("Saved milestone after relaunch", app: app)
    }

    func testFourthSelectionCancellationAndReplacement() throws {
        let app = launch(seed: true)
        let fourth = visibility("A saved memory", in: app)
        reveal(fourth, in: app)
        XCTAssertEqual(fourth.value as? String, "0")
        fourth.tap()
        capture("Fourth selection replacement", app: app)
        XCTAssertTrue(app.sheets["Choose a milestone to replace"].waitForExistence(timeout: 5), app.debugDescription)
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap() }
        XCTAssertEqual(fourth.value as? String, "0")
        fourth.tap()
        app.buttons["The next chapter"].tap()
        XCTAssertEqual(fourth.value as? String, "1")
        let replaced = visibility("The next chapter", in: app)
        reveal(replaced, in: app)
        XCTAssertEqual(replaced.value as? String, "0")
        XCTAssertTrue(row("The next chapter", in: app).exists)
        capture("Replacement preserves saved milestone", app: app)
    }

    func testSavingAdditionalHiddenMilestoneAndDeleting() throws {
        let app = launch(seed: true)
        app.buttons["addMilestone"].tap()
        let title = app.textFields["milestoneTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Another saved milestone")
        app.buttons["saveMilestone"].tap()
        let newRow = row("Another saved milestone", in: app)
        reveal(newRow, in: app)
        XCTAssertEqual(visibility("Another saved milestone", in: app).value as? String, "0")
        newRow.press(forDuration: 1.2)
        app.buttons["Delete Milestone"].tap()
        XCTAssertTrue(app.buttons["Delete Milestone"].waitForExistence(timeout: 5))
        app.buttons["Delete Milestone"].tap()
        XCTAssertFalse(row("Another saved milestone", in: app).waitForExistence(timeout: 2))
    }

    func testAllHiddenRetainsMilestones() throws {
        let app = launch(seed: true)
        for title in ["A new adventure", "The next chapter", "A quiet celebration"] {
            let toggle = visibility(title, in: app)
            reveal(toggle, in: app); toggle.tap()
            XCTAssertEqual(toggle.value as? String, "0")
        }
        app.terminate()
        let reopened = launch(preserve: true)
        XCTAssertTrue(reopened.staticTexts["Choose milestones in the app."].waitForExistence(timeout: 5))
        XCTAssertTrue(row("A new adventure", in: reopened).exists)
        capture("All milestones hidden and preserved", app: reopened)
    }

    func testLocalizedLibraryAndEditor() throws {
        for (language, expected) in [("en", "Make today count."), ("ja", "今、この瞬間を大切に。"), ("id", "Hargai hari ini.")] {
            let app = launch(seed: true, language: language)
            XCTAssertTrue(app.staticTexts[expected].waitForExistence(timeout: 5))
            capture("Library \(language)", app: app)
            app.buttons["addMilestone"].tap()
            XCTAssertTrue(app.textFields["milestoneTitle"].waitForExistence(timeout: 5))
            capture("Editor \(language)", app: app)
            app.terminate()
        }
    }

    func testAgeTargetValidationAndClockDisplay() throws {
        let app = launch()
        app.buttons["addMilestone"].tap()
        app.buttons["saveMilestone"].tap()
        XCTAssertTrue(app.alerts["Please check your milestone"].waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        let title = app.textFields["milestoneTitle"]
        title.tap(); title.typeText("A future birthday")
        app.buttons["dismissKeyboard"].tap()
        app.buttons["targetMode"].tap()
        app.buttons["Age"].tap()
        let age = app.textFields["targetAge"]
        reveal(age, in: app); age.tap(); age.typeText("80")
        app.buttons["dismissKeyboard"].tap()
        let display = app.buttons["countdownMode"]
        reveal(display, in: app); display.tap()
        app.buttons["Days + Clock"].tap()
        capture("Age target and clock editor", app: app)
        app.buttons["saveMilestone"].tap()
        XCTAssertTrue(row("A future birthday", in: app).waitForExistence(timeout: 5))
        capture("Age target clock library", app: app)
        row("A future birthday", in: app).tap()
        XCTAssertEqual(app.textFields["targetAge"].value as? String, "80")
    }

    func testWidgetLinkOpensMilestoneList() throws {
        let app = launch(seed: true)
        app.buttons["addMilestone"].tap()
        XCTAssertTrue(app.textFields["milestoneTitle"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.open(URL(string: "lifeisshort://milestones")!)
        XCTAssertTrue(app.buttons["addMilestone"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["milestoneTitle"].exists)
    }

    func testPhotoPickerImport() throws {
        let app = launch()
        app.buttons["addMilestone"].tap()
        let title = app.textFields["milestoneTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("A photo milestone")
        app.buttons["choosePhoto"].tap()
        capture("System photo picker", app: app)

        let photo = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 35), app.debugDescription)
        photo.tap()
        XCTAssertTrue(app.buttons["removePhoto"].waitForExistence(timeout: 15), app.debugDescription)
        capture("Imported photo editor", app: app)
        app.buttons["saveMilestone"].tap()
        XCTAssertTrue(row("A photo milestone", in: app).waitForExistence(timeout: 5))
        capture("Imported photo library", app: app)
        XCUIDevice.shared.press(.home)
        let home = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let photoWidget = home.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "A photo milestone")).firstMatch
        if !photoWidget.waitForExistence(timeout: 40) { placeWidget(in: home) }
        XCTAssertTrue(photoWidget.waitForExistence(timeout: 40), home.debugDescription)
        capture("Imported photo Home Screen widget", app: home)
        placeWidget(in: home, medium: true)
        XCTAssertTrue(photoWidget.waitForExistence(timeout: 40), home.debugDescription)
        capture("Imported photo medium Home Screen widget", app: home)
        app.activate()
    }

    func testLargeLibraryRemainsEditable() throws {
        let app = launch(seed: true, extra: ["-seed-200"])
        capture("Synthetic 200 milestone library", app: app)
        let first = row("A new adventure", in: app)
        reveal(first, in: app); first.tap()
        let title = app.textFields["milestoneTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "A new adventure".count))
        title.typeText("A library with 200 milestones")
        app.buttons["saveMilestone"].tap()
        app.terminate()
        let reopened = launch(preserve: true)
        XCTAssertTrue(row("A library with 200 milestones", in: reopened).waitForExistence(timeout: 5))
        capture("Edited 200 milestone library after relaunch", app: reopened)
    }

    func testScheduledWidgetRotation() throws {
        let app = launch(seed: true, extra: ["-seed-rotation-proof"])
        XCUIDevice.shared.press(.home)
        let home = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        func widget(_ title: String) -> XCUIElement {
            home.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        }
        if !widget("A new adventure").waitForExistence(timeout: 15) { placeWidget(in: home) }
        XCTAssertTrue(widget("A new adventure").waitForExistence(timeout: 10), home.debugDescription)
        capture("Widget rotation first milestone", app: home)
        XCTAssertTrue(widget("The next chapter").waitForExistence(timeout: 45), home.debugDescription)
        capture("Widget rotation second milestone", app: home)
        app.activate()
    }

    func testWidgetRenderingAndZero() throws {
        let app = launch(extra: ["-seed-widget-proof"])
        XCUIDevice.shared.press(.home)
        let home = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let widget = home.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Widget rendering proof")).firstMatch
        if !widget.waitForExistence(timeout: 5) { placeWidget(in: home) }
        XCTAssertTrue(widget.waitForExistence(timeout: 40), home.debugDescription)
        capture("Live widget long duration", app: home)
        let initial = widget.label
        let changed = NSPredicate { _, _ in widget.exists && widget.label != initial }
        expectation(for: changed, evaluatedWith: nil)
        waitForExpectations(timeout: 15)
        capture("Live widget seconds later", app: home)
        widget.tap()
        XCTAssertTrue(app.buttons["addMilestone"].waitForExistence(timeout: 10))
        app.terminate()
        let crossing = launch(extra: ["-seed-zero-crossing"])
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(widget.waitForExistence(timeout: 40), home.debugDescription)
        capture("Widget before target", app: home)
        let zero = NSPredicate { _, _ in widget.exists && widget.label.contains("00:00:00") }
        expectation(for: zero, evaluatedWith: nil)
        waitForExpectations(timeout: 45)
        capture("Widget stopped at zero", app: home)
        let observedZero = Date.now
        expectation(for: NSPredicate { _, _ in
            Date.now.timeIntervalSince(observedZero) > 3 && widget.label.contains("00:00:00")
        }, evaluatedWith: nil)
        waitForExpectations(timeout: 6)
        crossing.terminate()
        let dayBoundary = launch(extra: ["-seed-day-crossing"])
        XCUIDevice.shared.press(.home)
        expectation(for: NSPredicate { _, _ in
            widget.exists && widget.label.contains("1 day")
        }, evaluatedWith: nil)
        waitForExpectations(timeout: 15)
        capture("Widget before 24 hour boundary", app: home)
        expectation(for: NSPredicate { _, _ in
            widget.exists && widget.label.contains("0 days") && widget.label.contains("23:59:")
        }, evaluatedWith: nil)
        waitForExpectations(timeout: 40)
        capture("Widget after 24 hour boundary", app: home)
        dayBoundary.activate()
    }

    func testAddHomeScreenWidget() throws {
        let app = launch(seed: true)
        XCUIDevice.shared.press(.home)
        let home = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        placeWidget(in: home)
        XCTAssertTrue(home.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "A new adventure")).firstMatch.waitForExistence(timeout: 40), home.debugDescription)
        capture("Home Screen widget", app: home)
        app.activate()
    }

    private func placeWidget(in home: XCUIApplication, medium: Bool = false) {
        let icons = home.icons.matching(identifier: "Life Is Short")
        XCTAssertTrue(icons.firstMatch.waitForExistence(timeout: 10))
        let icon = icons.allElementsBoundByIndex.first { $0.frame.width < 100 && $0.isHittable } ?? icons.firstMatch
        icon.press(forDuration: 1.5)

        let edit = home.buttons["Edit Home Screen"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5), home.debugDescription)
        edit.tap()
        let editButton = home.buttons["Edit"]
        if editButton.waitForExistence(timeout: 3) { editButton.tap() }
        let add = home.buttons["Add Widget"]
        XCTAssertTrue(add.waitForExistence(timeout: 5), home.debugDescription)
        add.tap()

        let search = home.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), home.debugDescription)
        search.tap(); search.typeText("Life Is Short")

        let result = home.cells["Life Is Short"]
        XCTAssertTrue(result.waitForExistence(timeout: 5), home.debugDescription)
        result.tap()
        if medium {
            let preview = home.buttons.matching(NSPredicate(format: "value == %@", "Widget, Small")).firstMatch
            XCTAssertTrue(preview.waitForExistence(timeout: 5), home.debugDescription)
            preview.swipeLeft()
            XCTAssertTrue(home.buttons.matching(NSPredicate(format: "value == %@", "Widget, Medium")).firstMatch.waitForExistence(timeout: 5), home.debugDescription)
        }
        capture(medium ? "Medium widget gallery" : "Widget gallery", app: home)
        let addWidget = home.buttons.matching(NSPredicate(format: "label ENDSWITH %@", "Add Widget")).firstMatch
        XCTAssertTrue(addWidget.waitForExistence(timeout: 5), home.debugDescription)
        addWidget.tap()
        if home.buttons["Done"].waitForExistence(timeout: 3) { home.buttons["Done"].tap() }
        capture("Home Screen widget", app: home)
    }
}
