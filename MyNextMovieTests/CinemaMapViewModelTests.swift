import Testing

@testable import MyNextMovie

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
