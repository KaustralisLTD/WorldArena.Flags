import XCTest
import MapKit
@testable import World_Arena__Flags

final class CountryBoundaryTests: XCTestCase {
    func testAustraliaViewportIncludesMainlandAndTasmania() throws {
        let rect = try XCTUnwrap(CountryFactBoundaries.focusRect(polygons: CountryFactBoundaries.polygons(for: "AUS"), near: .init(latitude: -25, longitude: 133)))
        for point in [CLLocationCoordinate2D(latitude: -25, longitude: 133), .init(latitude: -42, longitude: 147)] {
            XCTAssertTrue(rect.contains(MKMapPoint(point)))
        }
        XCTAssertGreaterThan(rect.width, MKMapRect.world.width * 0.1)
        XCTAssertLessThan(rect.height, MKMapRect.world.height * 0.2)
    }
    func testFijiIncludesBothMainIslandsWithoutWorldZoom() throws {
        let rect = try XCTUnwrap(CountryFactBoundaries.focusRect(polygons: CountryFactBoundaries.polygons(for: "FJI"), near: .init(latitude: -18, longitude: 175)))
        XCTAssertTrue(rect.contains(MKMapPoint(.init(latitude: -17.8, longitude: 178))))
        XCTAssertTrue(rect.contains(MKMapPoint(.init(latitude: -16.6, longitude: 179.2))))
        XCTAssertLessThan(rect.width, MKMapRect.world.width / 8)
    }
    func testEveryCatalogCountryHasGeometryAndFiniteViewport() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "game_countries", withExtension: "json"))
        let countries = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: Any]])
        for country in countries {
            let code = try XCTUnwrap(country["cca3"] as? String)
            let coords = try XCTUnwrap(country["latlng"] as? [Double])
            let polygons = CountryFactBoundaries.polygons(for: code)
            XCTAssertFalse(polygons.isEmpty, code)
            let rect = try XCTUnwrap(CountryFactBoundaries.viewport(polygons: polygons, near: .init(latitude: coords[0], longitude: coords[1]), size: .init(width: 340, height: 130)), code)
            XCTAssertTrue(rect.width.isFinite && rect.height.isFinite && rect.width > 0 && rect.height > 0, code)
        }
    }
    func testReminderReceiptSurvivesReopeningAndIsSenderScoped() {
        let suite = "reminder-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date()
        FriendReminderHistory.record(sender: "Alice", recipient: "Bob", now: now, defaults: defaults)
        XCTAssertTrue(FriendReminderHistory.sentToday(sender: "alice", recipient: "bob", now: now, defaults: defaults))
        XCTAssertFalse(FriendReminderHistory.sentToday(sender: "Carol", recipient: "Bob", now: now, defaults: defaults))
        XCTAssertFalse(FriendReminderHistory.sentToday(sender: "Alice", recipient: "Bob", now: Calendar.current.date(byAdding: .day, value: 1, to: now)!, defaults: defaults))
    }
}
