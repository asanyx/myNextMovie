import Foundation
import Observation

@Observable
final class CinemaDetailViewModel {
    let cinema: Cinema
    let userLocation: UserLocation

    var travelMode = TravelMode.walking
    private(set) var route = noRoute
    private(set) var routeState = LoadState.idle
    private(set) var errorMessage = ""

    private let findRoute: CinemaRouteFinder

    init(
        cinema: Cinema,
        userLocation: UserLocation,
        findRoute: @escaping CinemaRouteFinder
    ) {
        self.cinema = cinema
        self.userLocation = userLocation
        self.findRoute = findRoute
    }

    var canFindRoute: Bool {
        return userLocation.isKnown
    }

    func loadRoute() async {
        guard canFindRoute else {
            return
        }

        routeState = .loading
        errorMessage = ""
        do {
            route = try await findRoute(userLocation, cinema, travelMode)
            routeState = .loaded
        } catch {
            route = noRoute
            routeState = .failed
            errorMessage = error.localizedDescription
        }
    }
}

func formattedTravelTime(_ travelTime: TimeInterval) -> String {
    guard travelTime > 0 else {
        return ""
    }
    let minutes = Int((travelTime / 60).rounded())
    return "\(minutes) min"
}

func routeSummary(_ route: CinemaRoute) -> String {
    let travelTime = formattedTravelTime(route.travelTime)
    let distance = formattedDistance(route.distanceInMeters)
    return [travelTime, distance]
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
}
