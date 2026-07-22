import CoreLocation
import Foundation

enum FindMyDeviceSnapshot {
    static func response(from dataSource: Any) -> [String: Any] {
        guard let mediator = child(named: "mediator", in: dataSource) else {
            return errorResponse("Find My Devices mediator is unavailable")
        }
        guard let devicesProvider = child(named: "devicesProvider", in: mediator) else {
            return errorResponse("Find My Devices provider is unavailable")
        }
        guard let manager = child(named: "fmipManager", in: devicesProvider) else {
            return errorResponse("Find My Devices manager is unavailable")
        }
        guard let dataManager = child(named: "dataManager", in: manager) else {
            return errorResponse("Find My Devices data manager is unavailable")
        }
        guard let devices = child(named: "devices", in: dataManager) else {
            return errorResponse("Find My Devices collection is unavailable")
        }

        let devicesMirror = Mirror(reflecting: devices)
        guard devicesMirror.displayStyle == .collection else {
            return errorResponse("Find My Devices collection has an unexpected type")
        }

        var skippedDeviceCount = 0
        let serializedDevices = devicesMirror.children.compactMap { child -> [String: Any]? in
            guard let device = serializeDevice(child.value) else {
                skippedDeviceCount += 1
                return nil
            }
            return device
        }.sorted(by: deviceSortOrder)

        return [
            "devices": serializedDevices,
            "partial": skippedDeviceCount > 0,
            "skippedDevices": skippedDeviceCount,
        ]
    }

    private static func errorResponse(_ message: String) -> [String: Any] {
        return [
            "error": message,
            "devices": [],
        ]
    }

    private static func serializeDevice(_ value: Any) -> [String: Any]? {
        guard let identifier = firstString(
            named: ["identifier", "discoveryIdentifier", "baIdentifier"],
            in: value
        ) else {
            return nil
        }

        var device: [String: Any] = ["identifier": identifier]
        copyString(named: "name", from: value, to: &device)
        copyString(named: "displayName", from: value, to: &device)
        copyString(named: "model", from: value, to: &device)
        copyString(named: "rawDeviceModel", from: value, to: &device)
        copyString(named: "systemVersion", from: value, to: &device)
        copyString(named: "discoveryIdentifier", from: value, to: &device)
        copyString(named: "baIdentifier", from: value, to: &device)
        copyString(named: "category", from: value, to: &device)

        if let batteryLevel = number(child(named: "batteryLevel", in: value)) {
            device["batteryLevel"] = batteryLevel
        }
        if let batteryStatus = enumCase(child(named: "batteryStatus", in: value)) {
            device["batteryStatus"] = batteryStatus
        }
        if let connectedState = enumCase(child(named: "deviceConnectedState", in: value)) {
            device["deviceConnectedState"] = connectedState
        }
        if let address = serializeAddress(child(named: "address", in: value)) {
            device["address"] = address
        }
        if let location = serializeLocation(child(named: "location", in: value)) {
            device["location"] = location
        }
        if let crowdSourcedLocation = serializeLocation(child(named: "crowdSourcedLocation", in: value)) {
            device["crowdSourcedLocation"] = crowdSourcedLocation
        }

        return device
    }

    private static func serializeAddress(_ value: Any?) -> [String: Any]? {
        guard let address = unwrapped(value) else {
            return nil
        }

        var serializedAddress: [String: Any] = [:]
        copyString(named: "label", from: address, to: &serializedAddress)
        copyString(named: "countryCode", from: address, to: &serializedAddress)
        copyString(named: "administrativeArea", from: address, to: &serializedAddress)
        copyString(named: "locality", from: address, to: &serializedAddress)

        if let formattedAddress = firstString(
            named: ["mapItemFormattedAddress", "largeAddressModern", "mediumAddressModern", "label"],
            in: address
        ) {
            serializedAddress["mapItemFullAddress"] = formattedAddress
            serializedAddress["formattedAddressLines"] = [formattedAddress]
        }

        return serializedAddress.isEmpty ? nil : serializedAddress
    }

    private static func serializeLocation(_ value: Any?) -> [String: Any]? {
        guard let locationWrapper = unwrapped(value) else {
            return nil
        }

        let coreLocation: CLLocation?
        if let directLocation = locationWrapper as? CLLocation {
            coreLocation = directLocation
        } else {
            coreLocation = unwrapped(child(named: "location", in: locationWrapper)) as? CLLocation
        }
        guard let coreLocation else {
            return nil
        }

        let coordinate = coreLocation.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate),
              coordinate.latitude.isFinite,
              coordinate.longitude.isFinite else {
            return nil
        }

        var serializedLocation: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "timeStamp": coreLocation.timestamp.timeIntervalSince1970 * 1_000,
        ]
        copyAccuracy(coreLocation.horizontalAccuracy, named: "horizontalAccuracy", to: &serializedLocation)
        copyAccuracy(coreLocation.verticalAccuracy, named: "verticalAccuracy", to: &serializedLocation)
        copyFinite(coreLocation.altitude, named: "altitude", to: &serializedLocation)

        if let floorLevel = number(child(named: "floor", in: locationWrapper)) {
            serializedLocation["floorLevel"] = floorLevel
        } else if let floorLevel = coreLocation.floor?.level {
            serializedLocation["floorLevel"] = floorLevel
        }
        if let isInaccurate = boolean(child(named: "isInaccurate", in: locationWrapper)) {
            serializedLocation["isInaccurate"] = isInaccurate
        }
        if let isOld = boolean(child(named: "isOld", in: locationWrapper)) {
            serializedLocation["isOld"] = isOld
        }
        if let isLocationFinished = boolean(child(named: "isLocationFinished", in: locationWrapper)) {
            serializedLocation["locationFinished"] = isLocationFinished
        }
        if let locationType = enumCase(child(named: "locationType", in: locationWrapper)) {
            serializedLocation["positionType"] = locationType
        }

        return serializedLocation
    }

    private static func copyString(named name: String, from source: Any, to destination: inout [String: Any]) {
        if let value = string(child(named: name, in: source)) {
            destination[name] = value
        }
    }

    private static func copyFinite(_ value: Double, named name: String, to destination: inout [String: Any]) {
        if value.isFinite {
            destination[name] = value
        }
    }

    private static func copyAccuracy(_ value: Double, named name: String, to destination: inout [String: Any]) {
        if value.isFinite, value >= 0 {
            destination[name] = value
        }
    }

    private static func firstString(named names: [String], in value: Any) -> String? {
        return names.lazy.compactMap { string(child(named: $0, in: value)) }.first
    }

    private static func child(named name: String, in value: Any) -> Any? {
        guard let root = unwrapped(value) else {
            return nil
        }

        var mirror: Mirror? = Mirror(reflecting: root)
        while let currentMirror = mirror {
            if let child = currentMirror.children.first(where: { $0.label == name }) {
                return unwrapped(child.value)
            }
            mirror = currentMirror.superclassMirror
        }
        return nil
    }

    private static func unwrapped(_ value: Any?) -> Any? {
        guard var currentValue = value else {
            return nil
        }

        while Mirror(reflecting: currentValue).displayStyle == .optional {
            guard let wrappedValue = Mirror(reflecting: currentValue).children.first?.value else {
                return nil
            }
            currentValue = wrappedValue
        }
        return currentValue
    }

    private static func string(_ value: Any?) -> String? {
        guard let unwrappedValue = unwrapped(value) else {
            return nil
        }

        let candidate: String?
        if let stringValue = unwrappedValue as? String {
            candidate = stringValue
        } else if let uuidValue = unwrappedValue as? UUID {
            candidate = uuidValue.uuidString
        } else {
            candidate = nil
        }

        let trimmedValue = candidate?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue?.isEmpty == false ? trimmedValue : nil
    }

    private static func number(_ value: Any?) -> Double? {
        guard let unwrappedValue = unwrapped(value), !(unwrappedValue is Bool) else {
            return nil
        }

        let numericValue: Double?
        if let numberValue = unwrappedValue as? NSNumber {
            numericValue = numberValue.doubleValue
        } else if let doubleValue = unwrappedValue as? Double {
            numericValue = doubleValue
        } else if let floatValue = unwrappedValue as? Float {
            numericValue = Double(floatValue)
        } else if let integerValue = unwrappedValue as? Int {
            numericValue = Double(integerValue)
        } else {
            numericValue = nil
        }

        guard let numericValue, numericValue.isFinite else {
            return nil
        }
        return numericValue
    }

    private static func boolean(_ value: Any?) -> Bool? {
        return unwrapped(value) as? Bool
    }

    private static func enumCase(_ value: Any?) -> String? {
        guard let unwrappedValue = unwrapped(value) else {
            return nil
        }
        if let stringValue = string(unwrappedValue) {
            return stringValue
        }

        let mirror = Mirror(reflecting: unwrappedValue)
        guard mirror.displayStyle == .enum else {
            return nil
        }
        if let caseName = mirror.children.first?.label, !caseName.isEmpty {
            return caseName
        }

        let caseName = String(describing: unwrappedValue)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return caseName.isEmpty ? nil : caseName
    }

    private static func deviceSortOrder(_ left: [String: Any], _ right: [String: Any]) -> Bool {
        let leftName = (left["name"] as? String) ?? (left["displayName"] as? String) ?? ""
        let rightName = (right["name"] as? String) ?? (right["displayName"] as? String) ?? ""
        let nameComparison = leftName.localizedCaseInsensitiveCompare(rightName)
        if nameComparison != .orderedSame {
            return nameComparison == .orderedAscending
        }

        let leftIdentifier = left["identifier"] as? String ?? ""
        let rightIdentifier = right["identifier"] as? String ?? ""
        return leftIdentifier < rightIdentifier
    }
}

@_cdecl("BlueBubblesFindMyCopyDevicesSnapshot")
public func blueBubblesFindMyCopyDevicesSnapshot(
    _ dataSourcePointer: UnsafeMutableRawPointer?
) -> UnsafeMutableRawPointer? {
    guard let dataSourcePointer else {
        let response = ["error": "Find My Devices data source is unavailable"]
        return Unmanaged.passRetained(response as NSDictionary).toOpaque()
    }

    let dataSource = Unmanaged<AnyObject>.fromOpaque(dataSourcePointer).takeUnretainedValue()
    let response = FindMyDeviceSnapshot.response(from: dataSource)
    return Unmanaged.passRetained(response as NSDictionary).toOpaque()
}
