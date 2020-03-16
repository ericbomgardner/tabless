import XCTest

@testable import Tabless

class URLBuilderTestCase: XCTestCase {

    func testURLDetection() {
        XCTAssertEqual(
            URLBuilder.createURL("apple.com")?.absoluteString,
            "https://apple.com"
        )

        XCTAssertEqual(
            URLBuilder.createURL("https://tabless.app")?.absoluteString,
            "https://tabless.app"
        )

        XCTAssertEqual(
             URLBuilder.createURL("tabless.app")?.absoluteString,
             "https://tabless.app"
        )

        XCTAssertEqual(
            URLBuilder.createURL("rl site:reddit.com")?.absoluteString,
            "https://www.google.com/search?q=rl%20site:reddit.com"
        )

        XCTAssertEqual(
            URLBuilder.createURL("site:reddit.com rl")?.absoluteString,
            "https://www.google.com/search?q=site:reddit.com%20rl"
        )

        XCTAssertEqual(
            URLBuilder.createURL("https://tabless.app")?.absoluteString,
            "https://tabless.app"
        )
    }
}
