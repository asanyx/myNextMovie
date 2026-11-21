import MapKit
import Testing

@testable import MyNextMovie

@MainActor
struct CinemaDetailViewModelTests {
    @Test
    func findsNoRouteWithoutLocation() async {
        var requestCount = 0
        let viewModel = CinemaDetailViewModel(
            cinema: testCinemaDCF,
            userLocation: fallbackUserLocation,
            findRoute: { _, _, _ in
                requestCount += 1
                return testRoute
            }
        )

        await viewModel.loadRoute()

        #expect(requestCount == 0)
        #expect(viewModel.routeState == .idle)
    }

    @Test
    func findsRouteForSelectedTravelMode() async {
        var requestedMode = TravelMode.walking
        let viewModel = makeDetailViewModel(
            findRoute: { _, _, travelMode in
                requestedMode = travelMode
                return testRoute
            }
        )
        viewModel.travelMode = .driving

        await viewModel.loadRoute()

        #expect(requestedMode == .driving)
        #expect(viewModel.routeState == .loaded)
        #expect(viewModel.route.travelTime == testRoute.travelTime)
        #expect(viewModel.route.distanceInMeters == testRoute.distanceInMeters)
    }

    @Test
    func showsErrorWhenRouteFails() async {
        let viewModel = makeDetailViewModel(
            findRoute: { _, _, _ in
                throw NoRouteFound()
            }
        )

        await viewModel.loadRoute()

        #expect(viewModel.routeState == .failed)
        #expect(viewModel.errorMessage == "Maps found no way to this cinema.")
    }

    @Test
    func routeSummaryHasTimeAndDistance() {
        #expect(formattedTravelTime(12 * 60) == "12 min")
        #expect(routeSummary(testRoute) == "12 min · 950 m")
    }

    private var testRoute: CinemaRoute {
        return CinemaRoute(
            line: MKPolyline(),
            travelTime: 12 * 60,
            distanceInMeters: 950
        )
    }

    private func makeDetailViewModel(
        findRoute: @escaping CinemaRouteFinder
    ) -> CinemaDetailViewModel {
        return CinemaDetailViewModel(
            cinema: testCinemaDCF,
            userLocation: testUserLocation,
            findRoute: findRoute
        )
    }
}

@MainActor
struct CinemaMapViewModelTests {
    @Test
    func showsCinemasAtOnceByName() {
        let viewModel = makeViewModel()

        #expect(
            namesOf(viewModel.cinemas) == [
                "DCF",
                "Helios Magnolia",
                "Kino Nowe Horyzonty",
                "Multikino Pasaż Grunwaldzki",
            ])
    }

    @Test
    func sortsByDistanceOnceUserIsFound() async {
        let viewModel = makeViewModel(
            findUserLocation: { testUserLocation }
        )

        await viewModel.locateUser()

        #expect(
            namesOf(viewModel.cinemas) == [
                "DCF",
                "Kino Nowe Horyzonty",
                "Multikino Pasaż Grunwaldzki",
                "Helios Magnolia",
            ])
        #expect(
            viewModel.cinemas.allSatisfy {
                $0.distanceInMeters != unknownDistance
            })
    }

    @Test
    func lastKnownLocationIsUsedWhenNoFreshOneComes() async {
        let viewModel = makeViewModel(
            findUserLocation: { fallbackUserLocation },
            lastKnownLocation: { testUserLocation }
        )

        await viewModel.locateUser()

        #expect(viewModel.userLocation == testUserLocation)
        #expect(viewModel.cinemas.first?.id == testCinemaDCF.id)
    }

    @Test
    func freshLocationReplacesLastKnownOne() async {
        let freshLocation = UserLocation(
            latitude: testCinemaHelios.latitude,
            longitude: testCinemaHelios.longitude,
            isKnown: true
        )
        let viewModel = makeViewModel(
            findUserLocation: { freshLocation },
            lastKnownLocation: { testUserLocation }
        )

        await viewModel.locateUser()

        #expect(viewModel.userLocation == freshLocation)
        #expect(viewModel.cinemas.first?.id == testCinemaHelios.id)
    }

    @Test
    func saysWhenLocationIsUnavailable() async {
        let viewModel = makeViewModel()

        #expect(!viewModel.isLocationUnavailable)

        await viewModel.locateUser()

        #expect(viewModel.isLocationUnavailable)
    }

    @Test
    func asksForLocationOnlyOnce() async {
        var requestCount = 0
        let viewModel = makeViewModel(
            findUserLocation: {
                requestCount += 1
                return testUserLocation
            }
        )

        await viewModel.locateUserIfNeeded()
        await viewModel.locateUserIfNeeded()

        #expect(requestCount == 1)
    }

    @Test
    func togglesSelection() {
        let viewModel = makeViewModel()
        let cinema = testCinemaDCF

        viewModel.toggleCinema(cinema)
        #expect(viewModel.selectedCinemaId == cinema.id)

        viewModel.toggleCinema(cinema)
        #expect(viewModel.selectedCinemaId == noCinemaSelected)
    }

    private func makeViewModel(
        findUserLocation: @escaping UserLocationFinder = {
            fallbackUserLocation
        },
        lastKnownLocation: @escaping LastKnownLocationReader = {
            fallbackUserLocation
        }
    ) -> CinemaMapViewModel {
        return CinemaMapViewModel(
            cinemas: testCinemas,
            findUserLocation: findUserLocation,
            lastKnownLocation: lastKnownLocation
        )
    }
}
