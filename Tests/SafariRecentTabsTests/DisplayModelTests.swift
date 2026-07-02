import XCTest
@testable import SafariRecentTabsCore

final class DisplayModelTests: XCTestCase {
    func testDisplayModelUsesTitleAndRegistrableDomain() {
        let tab = SafariTab(
            windowID: 2,
            index: 4,
            title: "Project Plan",
            url: URL(string: "https://docs.google.com/document/d/abc")!
        )

        let display = TabDisplayModel(tab: tab)

        XCTAssertEqual(display.title, "Project Plan")
        XCTAssertEqual(display.domain, "google.com")
        XCTAssertEqual(display.fallbackInitial, "G")
    }

    func testBlankTitleFallsBackToDomain() {
        let tab = SafariTab(
            windowID: 2,
            index: 4,
            title: "",
            url: URL(string: "https://developer.apple.com/documentation")!
        )

        let display = TabDisplayModel(tab: tab)

        XCTAssertEqual(display.title, "developer.apple.com")
        XCTAssertEqual(display.domain, "apple.com")
        XCTAssertEqual(display.fallbackInitial, "A")
    }
}
