import Foundation
import Observation

@Observable
final class CinemaMapViewModel {
    private(set) var cinemas: [Cinema]
    private(set) var userLocation = fallbackUserLocation
    var selectedCinemaId = noCinemaSelected
    var visibleRegion = wroclawMapRegion
    private(set) var didAskForLocation = false

    private let findUserLocation: UserLocationFinder
    private let lastKnownLocation: LastKnownLocationReader

    init(
        cinemas: [Cinema],
        findUserLocation: @escaping UserLocationFinder,
        lastKnownLocation: @escaping LastKnownLocationReader = {
            fallbackUserLocation
        }
    ) {
        self.cinemas = cinemas.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        self.findUserLocation = findUserLocation
        self.lastKnownLocation = lastKnownLocation
    }

    var isLocationUnavailable: Bool {
        return didAskForLocation && !userLocation.isKnown
    }

    func locateUser() async {
        didAskForLocation = true

        let lastLocation = lastKnownLocation()
        if lastLocation.isKnown {
            updateUserLocation(lastLocation)
        }

        let freshLocation = await findUserLocation()
        if freshLocation.isKnown {
            updateUserLocation(freshLocation)
        }
    }

    func locateUserIfNeeded() async {
        guard !didAskForLocation else {
            return
        }
        await locateUser()
    }

    func toggleCinema(_ cinema: Cinema) {
        if selectedCinemaId == cinema.id {
            selectedCinemaId = noCinemaSelected
        } else {
            selectedCinemaId = cinema.id
        }
    }

    private func updateUserLocation(_ location: UserLocation) {
        userLocation = location
        cinemas = cinemasSortedByDistance(cinemas, from: location)

        let coordinate = userCoordinate(location)
        if !isInRegion(coordinate, visibleRegion) {
            visibleRegion = regionMoved(visibleRegion, to: coordinate)
        }
    }
}
