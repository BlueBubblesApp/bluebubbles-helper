import CoreLocation
import Foundation

private enum MockBatteryStatus {
    case charging
}

private enum MockConnectedState {
    case online
}

private enum MockLocationType {
    case current
}

private struct MockAddress {
    let label: String?
    let mapItemFormattedAddress: String?
    let mediumAddressModern: String?
    let largeAddressModern: String?
    let locality: String?
    let administrativeArea: String?
    let countryCode: String?
}

private struct MockLocation {
    let location: CLLocation?
    let floor: Double?
    let isInaccurate: Bool
    let isLocationFinished: Bool
    let isOld: Bool
    let locationType: MockLocationType
}

private struct MockDevice {
    let identifier: String
    let name: String?
    let displayName: String?
    let model: String?
    let rawDeviceModel: String?
    let systemVersion: String?
    let batteryLevel: Double?
    let batteryStatus: MockBatteryStatus
    let deviceConnectedState: MockConnectedState
    let discoveryIdentifier: String?
    let baIdentifier: String?
    let category: String?
    let address: MockAddress?
    let location: MockLocation?
    let crowdSourcedLocation: MockLocation?
}

private struct MockDataManager {
    let devices: [MockDevice]
}

private struct MockManager {
    let dataManager: MockDataManager
}

private struct MockDevicesProvider {
    let fmipManager: MockManager
}

private struct MockMediator {
    let devicesProvider: MockDevicesProvider
}

private struct MockDataSource {
    let mediator: MockMediator
}

private func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        print("FAIL: \(message)")
        exit(1)
    }
}

private func dataSource(devices: [MockDevice]) -> MockDataSource {
    return MockDataSource(
        mediator: MockMediator(
            devicesProvider: MockDevicesProvider(
                fmipManager: MockManager(
                    dataManager: MockDataManager(devices: devices)
                )
            )
        )
    )
}

private func device(
    identifier: String,
    name: String?,
    location: MockLocation?,
    discoveryIdentifier: String? = "00000000-0000-4000-8000-000000000001"
) -> MockDevice {
    return MockDevice(
        identifier: identifier,
        name: name,
        displayName: "MacBook Pro",
        model: "Mac14,6",
        rawDeviceModel: "Mac14,6-silver",
        systemVersion: "15.7.7",
        batteryLevel: 0,
        batteryStatus: .charging,
        deviceConnectedState: .online,
        discoveryIdentifier: discoveryIdentifier,
        baIdentifier: nil,
        category: "MacBookPro",
        address: MockAddress(
            label: "Seattle, WA",
            mapItemFormattedAddress: "Seattle, WA",
            mediumAddressModern: nil,
            largeAddressModern: nil,
            locality: "Seattle",
            administrativeArea: "WA",
            countryCode: "US"
        ),
        location: location,
        crowdSourcedLocation: nil
    )
}

private func testPopulatedAndOfflineDevices() {
    let timestamp = Date(timeIntervalSince1970: 1_234.567)
    let coreLocation = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 47.61, longitude: -122.33),
        altitude: 32,
        horizontalAccuracy: 6.5,
        verticalAccuracy: 9,
        timestamp: timestamp
    )
    let currentLocation = MockLocation(
        location: coreLocation,
        floor: 4,
        isInaccurate: false,
        isLocationFinished: true,
        isOld: false,
        locationType: .current
    )

    let response = FindMyDeviceSnapshot.response(from: dataSource(devices: [
        device(identifier: "offline", name: "Zulu Device", location: nil),
        device(identifier: "online", name: "Alpha Device", location: currentLocation),
    ]))
    let devices = response["devices"] as? [[String: Any]]

    assert(response["error"] == nil, "a populated FMIP path must not return an error")
    assert(response["partial"] as? Bool == false, "identified records must form a complete snapshot")
    assert(devices?.count == 2, "online and offline devices must both remain in the snapshot")
    assert(devices?[0]["identifier"] as? String == "online", "devices must be sorted deterministically")
    assert(devices?[0]["batteryLevel"] as? Double == 0, "a zero battery level must not be treated as missing")
    assert(devices?[0]["batteryStatus"] as? String == "charging", "battery enum cases must be preserved")
    assert(devices?[0]["deviceConnectedState"] as? String == "online", "connection state must be preserved")
    assert(devices?[1]["location"] == nil, "an offline device must not gain a fabricated location")

    let location = devices?[0]["location"] as? [String: Any]
    assert(location?["latitude"] as? Double == 47.61, "latitude must be preserved")
    assert(location?["longitude"] as? Double == -122.33, "longitude must be preserved")
    let timestampMilliseconds = location?["timeStamp"] as? Double
    assert(abs((timestampMilliseconds ?? 0) - 1_234_567) < 0.001,
           "timestamps must be converted to milliseconds")
    assert(location?["floorLevel"] as? Double == 4, "floor level must be preserved")
    assert(location?["locationFinished"] as? Bool == true, "location completion state must be preserved")

    let address = devices?[0]["address"] as? [String: Any]
    assert(address?["mapItemFullAddress"] as? String == "Seattle, WA", "formatted address must be preserved")
    assert(address?["formattedAddressLines"] as? [String] == ["Seattle, WA"], "address lines must be explicit")
}

private func testUnavailableAndEmptyCollections() {
    let unavailable = FindMyDeviceSnapshot.response(from: NSObject())
    assert(unavailable["error"] as? String == "Find My Devices mediator is unavailable",
           "a missing app-owned object path must return an explicit error")

    let empty = FindMyDeviceSnapshot.response(from: dataSource(devices: []))
    assert((empty["devices"] as? [[String: Any]])?.isEmpty == true,
           "an initialized empty collection must remain distinguishable from an unavailable path")
    assert(empty["partial"] as? Bool == false, "an empty initialized collection must be complete")
}

private func testUnidentifiableDeviceMakesResponsePartial() {
    let response = FindMyDeviceSnapshot.response(from: dataSource(devices: [
        device(identifier: "   ", name: "Missing Identifier", location: nil, discoveryIdentifier: nil),
    ]))

    assert((response["devices"] as? [[String: Any]])?.isEmpty == true,
           "unidentifiable private records must not cross the API boundary")
    assert(response["partial"] as? Bool == true, "skipped private records must mark the response partial")
    assert(response["skippedDevices"] as? Int == 1, "skipped private records must be counted")
}

@main
private enum FindMyDeviceSnapshotTests {
    static func main() {
        testPopulatedAndOfflineDevices()
        testUnavailableAndEmptyCollections()
        testUnidentifiableDeviceMakesResponsePartial()
        print("PASS: FindMyDeviceSnapshotTests")
    }
}
