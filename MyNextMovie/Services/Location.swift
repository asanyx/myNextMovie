import CoreLocation

private let locationTimeout: Duration = .seconds(10)

func findUserLocation() async -> UserLocation {
    return await withTaskGroup(of: UserLocation.self) { group in
        group.addTask {
            return await requestUserLocation()
        }
        group.addTask {
            try? await Task.sleep(for: locationTimeout)
            return fallbackUserLocation
        }

        let location = await group.next() ?? fallbackUserLocation
        group.cancelAll()
        return location
    }
}

func lastKnownUserLocation() -> UserLocation {
    guard let location = CLLocationManager().location else {
        return fallbackUserLocation
    }
    return UserLocation(
        latitude: location.coordinate.latitude,
        longitude: location.coordinate.longitude,
        isKnown: true
    )
}

private func requestUserLocation() async -> UserLocation {
    let session = CLServiceSession(authorization: .whenInUse)
    defer { session.invalidate() }

    do {
        for try await update in CLLocationUpdate.liveUpdates() {
            if update.authorizationDenied || update.authorizationRestricted {
                return fallbackUserLocation
            }
            if let location = update.location {
                return UserLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    isKnown: true
                )
            }
        }
    } catch {
        return fallbackUserLocation
    }
    return fallbackUserLocation
}
