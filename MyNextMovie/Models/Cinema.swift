import CoreLocation
import Foundation

/// Distance of a cinema before the app knows where the user is.
nonisolated let unknownDistance: CLLocationDistance = -1

nonisolated let noCinemaSelected = ""
nonisolated let cinemaNotFound = -1

/// Rynek, used when the app does not know the user's position.
nonisolated let fallbackCoordinate = CLLocationCoordinate2D(
    latitude: 51.1100,
    longitude: 17.0320
)
nonisolated let fallbackUserLocation = UserLocation(
    latitude: fallbackCoordinate.latitude,
    longitude: fallbackCoordinate.longitude,
    isKnown: false
)

/// A cinema in Wrocław, a plain struct,
/// so the views and tests do not depend on `MKMapItem`.
nonisolated struct Cinema: Identifiable, Hashable {
    let id: String
    let name: String
    let address: String
    let phoneNumber: String
    let website: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    var distanceInMeters = unknownDistance
}

/// Where the user is. `isKnown` is false when the app does not know it.
nonisolated struct UserLocation: Equatable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let isKnown: Bool
}

nonisolated func cinemaCoordinate(_ cinema: Cinema) -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D(
        latitude: cinema.latitude,
        longitude: cinema.longitude
    )
}

nonisolated func userCoordinate(
    _ userLocation: UserLocation
) -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D(
        latitude: userLocation.latitude,
        longitude: userLocation.longitude
    )
}

nonisolated func distanceInMeters(
    from firstCoordinate: CLLocationCoordinate2D,
    to secondCoordinate: CLLocationCoordinate2D
) -> CLLocationDistance {
    let firstLocation = CLLocation(
        latitude: firstCoordinate.latitude,
        longitude: firstCoordinate.longitude
    )
    let secondLocation = CLLocation(
        latitude: secondCoordinate.latitude,
        longitude: secondCoordinate.longitude
    )
    return firstLocation.distance(from: secondLocation)
}

nonisolated func cinemasSortedByDistance(
    _ cinemas: [Cinema],
    from userLocation: UserLocation
) -> [Cinema] {
    let location = userCoordinate(userLocation)
    var measuredCinemas = cinemas

    for index in measuredCinemas.indices {
        measuredCinemas[index].distanceInMeters = distanceInMeters(
            from: location,
            to: cinemaCoordinate(measuredCinemas[index])
        )
    }

    return measuredCinemas.sorted(by: isCloser)
}

nonisolated func isCloser(_ firstCinema: Cinema, _ secondCinema: Cinema) -> Bool {
    if firstCinema.distanceInMeters == secondCinema.distanceInMeters {
        return firstCinema.name.localizedStandardCompare(secondCinema.name)
            == .orderedAscending
    }
    return firstCinema.distanceInMeters < secondCinema.distanceInMeters
}

nonisolated func positionOfCinema(
    _ cinemas: [Cinema],
    cinemaId: String
) -> Int {
    return cinemas.firstIndex { $0.id == cinemaId } ?? cinemaNotFound
}

nonisolated func containsCinema(
    _ cinemas: [Cinema],
    cinemaId: String
) -> Bool {
    return positionOfCinema(cinemas, cinemaId: cinemaId) != cinemaNotFound
}

nonisolated func formattedDistance(
    _ distance: CLLocationDistance
) -> String {
    if distance == unknownDistance {
        return ""
    }
    if distance < 1_000 {
        return "\(Int(distance.rounded())) m"
    }
    return String(format: "%.1f km", distance / 1_000)
}

nonisolated func phoneURL(_ cinema: Cinema) -> URL? {
    let phoneNumber = cinema.phoneNumber.filter {
        $0.isNumber || $0 == "+"
    }
    if phoneNumber.isEmpty {
        return nil
    }
    return URL(string: "tel:\(phoneNumber)")
}

nonisolated func hasPhoneNumber(_ cinema: Cinema) -> Bool {
    return phoneURL(cinema) != nil
}

nonisolated func websiteURL(_ cinema: Cinema) -> URL? {
    if cinema.website.isEmpty {
        return nil
    }
    return URL(string: cinema.website)
}

nonisolated func hasWebsite(_ cinema: Cinema) -> Bool {
    return websiteURL(cinema) != nil
}
