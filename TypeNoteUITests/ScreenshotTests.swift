import XCTest

/// Captures raw screenshots for App Store compositing.
/// Screenshots are saved as XCTAttachments inside the xcresult bundle.
/// Run 01_capture.sh to extract them automatically after the tests finish.
final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Kill any leftover TypeNote before each test for a clean slate
        run("/usr/bin/pkill", args: ["-x", "TypeNote"])
        Thread.sleep(forTimeInterval: 1.0)

        app = XCUIApplication()
        app.launch()

        // Wait until TypeNote is visible to System Events, then click its status item
        var clicked = false
        for _ in 1...8 {
            Thread.sleep(forTimeInterval: 0.75)
            let result = run("/usr/bin/osascript", args: ["-e", """
tell application "System Events"
    if not (exists process "TypeNote") then return "not_running"
    tell process "TypeNote"
        click menu bar item 1 of menu bar 2
    end tell
    return "ok"
end tell
"""])
            if result == 0 {
                clicked = true
                break
            }
        }
        guard clicked else {
            XCTFail("Could not click TypeNote status item")
            return
        }
        Thread.sleep(forTimeInterval: 1.0) // Wait for popover

        // Click the Library button inside the popover
        let libButton = app.buttons.matching(
            NSPredicate(format: "label == 'Library' OR label == '乐谱库'")
        ).firstMatch
        XCTAssertTrue(libButton.waitForExistence(timeout: 5), "Library button not found in popover")
        libButton.click()

        // Wait for Library window
        XCTAssertTrue(
            app.windows.firstMatch.waitForExistence(timeout: 10),
            "Library window did not appear after clicking Library button"
        )
        sleep(1) // Let animations settle
    }

    /// Run a process synchronously and discard output.
    @discardableResult
    private func run(_ path: String, args: [String]) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }

    override func tearDown() {
        super.tearDown()
        // MenuBarExtra apps hang on XCUIApplication.terminate(); use pkill instead.
        let kill = Process()
        kill.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        kill.arguments = ["-x", "TypeNote"]
        try? kill.run()
        kill.waitUntilExit()
        Thread.sleep(forTimeInterval: 1.0)
    }

    // MARK: - Helper

    /// Attach a screenshot to the test result with the given name.
    /// The name is used by xcresulttool to identify the exported PNG.
    func attach(_ element: XCUIElement, name: String) {
        let shot = element.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        print("  attached: \(name)")
    }

    var window: XCUIElement { app.windows.firstMatch }

    // MARK: - Screenshot 1: PlayOverlay (Hero)

    func test01_HeroPlayOverlay() throws {
        let playButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'playing' OR label CONTAINS 'Click here'")
        ).firstMatch

        if playButton.waitForExistence(timeout: 3) {
            playButton.click()
        } else {
            window.toolbars.firstMatch
                .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .click()
        }
        sleep(2) // Wait for overlay animation + bubbles

        attach(window, name: "hero_playoverlay")

        app.typeKey(.escape, modifierFlags: [])
        sleep(1)
    }

    // MARK: - Screenshot 2: Library — Score list

    func test02_LibraryScores() throws {
        attach(window, name: "library_scores")
    }

    // MARK: - Screenshot 3: Library — Instruments

    func test03_LibraryInstruments() throws {
        // Sidebar is SwiftUI List(.sidebar) → NSOutlineView in AppKit.
        let labelPredicate = NSPredicate(
            format: "label == 'Instruments' OR label == '乐器库'"
        )
        let instrumentsText = window.outlines.staticTexts.matching(labelPredicate).firstMatch
        if instrumentsText.waitForExistence(timeout: 3) {
            instrumentsText.click()
        } else {
            // Fallback: second cell in the sidebar outline (index 0 = Score Library)
            window.outlines.cells.element(boundBy: 1).click()
        }
        sleep(1)

        attach(window, name: "library_instruments")
    }

    // MARK: - Screenshot 4: MenuBar Popover

    func test04_MenuBarPopover() throws {
        // Close the Library window so only the popover is visible
        app.typeKey("w", modifierFlags: .command)
        sleep(1)

        // Click the TypeNote status item to open the popover
        var clicked = false
        for bundleID in ["com.apple.controlcenter", "com.apple.systemuiserver"] where !clicked {
            let host = XCUIApplication(bundleIdentifier: bundleID)
            let item = host.statusItems.firstMatch
            if item.waitForExistence(timeout: 3) {
                item.click()
                clicked = true
            }
        }
        sleep(2) // Wait for popover to animate in

        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "menubar_popover"
        attachment.lifetime = .keepAlways
        add(attachment)
        print("  attached: menubar_popover")

        app.typeKey(.escape, modifierFlags: [])
    }
}
