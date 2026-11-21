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

struct NoRouteFound: LocalizedError {
    var errorDescription: String? {
        return "Maps found no way to this cinema."
    }
}

func findMapKitRoute(
    userLocation: UserLocation,
    cinema: Cinema,
    travelMode: TravelMode
) async throws -> CinemaRoute {
    let request = MKDirections.Request()
    request.source = mapItem(
        coordinate: userCoordinate(userLocation),
        name: nil,
        address: nil
    )
    request.destination = mapItemForCinema(cinema)
    request.transportType = transportTypeForMapKit(travelMode)

    let response = try await MKDirections(request: request).calculate()
    guard let route = response.routes.first else {
        throw NoRouteFound()
    }
    return CinemaRoute(
        line: route.polyline,
        travelTime: route.expectedTravelTime,
        distanceInMeters: route.distance
    )
}

func mapItemForCinema(_ cinema: Cinema) -> MKMapItem {
    return mapItem(
        coordinate: cinemaCoordinate(cinema),
        name: cinema.name,
        address: cinema.address
    )
}

private func mapItem(
    coordinate: CLLocationCoordinate2D,
    name: String?,
    address: String?
) -> MKMapItem {
    let mapItem: MKMapItem
    if #available(iOS 26.0, *) {
        let mapAddress = address.flatMap {
            MKAddress(fullAddress: $0, shortAddress: nil)
        }
        mapItem = MKMapItem(
            location: CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            address: mapAddress
        )
    } else {
        let addressDictionary = address.map {
            ["FormattedAddressLines": [$0]]
        }
        let placemark = MKPlacemark(
            coordinate: coordinate,
            addressDictionary: addressDictionary
        )
        mapItem = MKMapItem(placemark: placemark)
    }
    mapItem.name = name
    return mapItem
}

func transportTypeForMapKit(
    _ travelMode: TravelMode
) -> MKDirectionsTransportType {
    switch travelMode {
    case .walking:
        return .walking
    case .driving:
        return .automobile
    }
}

func openCinemaInMaps(
    _ cinema: Cinema,
    travelMode: TravelMode
) {
    let directionsMode: String
    switch travelMode {
    case .walking:
        directionsMode = MKLaunchOptionsDirectionsModeWalking
    case .driving:
        directionsMode = MKLaunchOptionsDirectionsModeDriving
    }
    mapItemForCinema(cinema).openInMaps(
        launchOptions: [
            MKLaunchOptionsDirectionsModeKey: directionsMode
        ]
    )
}

func findLookAroundScene(_ cinema: Cinema) async -> MKLookAroundScene? {
    let request = MKLookAroundSceneRequest(coordinate: cinemaCoordinate(cinema))
    return try? await request.scene
}
