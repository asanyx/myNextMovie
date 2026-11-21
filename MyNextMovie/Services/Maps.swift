import MapKit

typealias UserLocationFinder = () async -> UserLocation
typealias LastKnownLocationReader = () -> UserLocation

enum TravelMode {
    case walking
    case driving
}

struct CinemaRoute {
    let line: MKPolyline
    let travelTime: TimeInterval
    let distanceInMeters: CLLocationDistance
}

typealias CinemaRouteFinder = (
    _ userLocation: UserLocation,
    _ cinema: Cinema,
    _ travelMode: TravelMode
) async throws -> CinemaRoute

let noRoute = CinemaRoute(
    line: MKPolyline(),
    travelTime: 0,
    distanceInMeters: unknownDistance
)
