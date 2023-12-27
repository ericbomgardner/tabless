import XCTest

@testable import Tabless

class URLBuilderTestCase: XCTestCase {

    func testURLDetection() {
        let urlBuilder = URLBuilder(searchEngine: .google)

        XCTAssertEqual(
            urlBuilder.createURL("apple.com")?.absoluteString,
            "https://apple.com"
        )

        XCTAssertEqual(
            urlBuilder.createURL("https://tabless.app")?.absoluteString,
            "https://tabless.app"
        )

        XCTAssertEqual(
             urlBuilder.createURL("tabless.app")?.absoluteString,
             "https://tabless.app"
        )

        XCTAssertEqual(
            urlBuilder.createURL("rl site:reddit.com")?.absoluteString,
            "https://www.google.com/search?q=rl%20site:reddit.com"
        )

        XCTAssertEqual(
            urlBuilder.createURL("site:reddit.com rl")?.absoluteString,
            "https://www.google.com/search?q=site:reddit.com%20rl"
        )

        XCTAssertEqual(
            urlBuilder.createURL("https://tabless.app")?.absoluteString,
            "https://tabless.app"
        )
    }

    func testCreatingURLsWithAlternativeSearchEngines() {
        var urlBuilder = URLBuilder(searchEngine: .duckDuckGo)

        XCTAssertEqual(
            urlBuilder.createURL("privacy")?.absoluteString,
            "https://duckduckgo.com/?q=privacy"
        )

        urlBuilder = URLBuilder(searchEngine: .kagi(token: "example_token"))

        XCTAssertEqual(
            urlBuilder.createURL("no ads")?.absoluteString,
            "https://kagi.com/search?token=example_token&q=no%20ads"
        )
    }
}
