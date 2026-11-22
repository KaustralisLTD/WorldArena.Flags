import XCTest
@testable import World_Arena__Flags

final class GoogleSignInSetupTests: XCTestCase {
    private let clientID = "123-example.apps.googleusercontent.com"
    private var validInfo: [String: Any] {
        ["GIDClientID": clientID, "CFBundleURLTypes": [["CFBundleURLSchemes": ["com.googleusercontent.apps.123-example"]]]]
    }
    func testValidOAuthConfiguration() {
        XCTAssertEqual(GoogleSignInSetup.clientID(info: validInfo), clientID)
    }
    func testMissingClientDoesNotReachSDK() {
        var info = validInfo; info.removeValue(forKey: "GIDClientID")
        XCTAssertNil(GoogleSignInSetup.clientID(info: info))
    }
    func testMissingOrMismatchedReturnSchemeDoesNotReachSDK() {
        var info = validInfo; info["CFBundleURLTypes"] = [["CFBundleURLSchemes": ["worldarenaflags"]]]
        XCTAssertNil(GoogleSignInSetup.clientID(info: info))
    }
    func testBuiltApplicationContainsOAuthSettings() {
        XCTAssertNotNil(GoogleSignInSetup.configuredClientID)
    }
}
