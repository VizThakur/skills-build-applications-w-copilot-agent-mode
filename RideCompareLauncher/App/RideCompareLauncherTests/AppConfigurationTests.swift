import XCTest
@testable import RideCompareLauncher

final class AppConfigurationTests: XCTestCase {
    func testResolvedValueReturnsTrimmedString() {
        XCTAssertEqual(AppConfiguration.resolvedValue(from: "  AIzaSyExampleKey  "), "AIzaSyExampleKey")
    }

    func testResolvedValueTreatsEmptyStringAsUnset() {
        XCTAssertNil(AppConfiguration.resolvedValue(from: ""))
        XCTAssertNil(AppConfiguration.resolvedValue(from: "   "))
    }

    func testResolvedValueTreatsUnsubstitutedBuildSettingAsUnset() {
        // What you get in Info.plist when GOOGLE_PLACES_API_KEY was never
        // defined in Secrets.xcconfig: Xcode leaves the placeholder as-is.
        XCTAssertNil(AppConfiguration.resolvedValue(from: "$(GOOGLE_PLACES_API_KEY)"))
    }
}
