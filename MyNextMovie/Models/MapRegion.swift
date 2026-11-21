import MapKit

let wroclawMapRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(
        latitude: 51.0956,
        longitude: 17.0230
    ),
    latitudinalMeters: 15_500,
    longitudinalMeters: 14_000
)

nonisolated func regionMoved(
    _ region: MKCoordinateRegion,
    to coordinate: CLLocationCoordinate2D
) -> MKCoordinateRegion {
    return MKCoordinateRegion(center: coordinate, span: region.span)
}

nonisolated func isInRegion(
    _ coordinate: CLLocationCoordinate2D,
    _ region: MKCoordinateRegion
) -> Bool {
    let latitudeDistance = abs(coordinate.latitude - region.center.latitude)
    let longitudeDistance = abs(coordinate.longitude - region.center.longitude)
    return latitudeDistance <= region.span.latitudeDelta / 2
        && longitudeDistance <= region.span.longitudeDelta / 2
}
