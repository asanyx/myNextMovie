import CoreLocation
import MapKit
import Testing

@testable import MyNextMovie

@MainActor
struct MapKitConversionTests {
    @Test
    func mapItemForCinemaKeepsNameAndPosition() {
        let mapItem = mapItemForCinema(testCinemaNoweHoryzonty)

        #expect(mapItem.name == testCinemaNoweHoryzonty.name)
        #expect(
            mapItem.placemark.coordinate.latitude
                == testCinemaNoweHoryzonty.latitude
        )
        #expect(
            mapItem.placemark.coordinate.longitude
                == testCinemaNoweHoryzonty.longitude
        )
    }

    @Test
    func travelModeBecomesMapKitTransportType() {
        #expect(transportTypeForMapKit(.walking) == .walking)
        #expect(transportTypeForMapKit(.driving) == .automobile)
    }
}

@MainActor
struct CinemaTests {
    @Test func sortsCinemasClosestFirst() {
        let sortedCinemas = cinemasSortedByDistance(
            testCinemas,
            from: testUserLocation
        )

        #expect(
            namesOf(sortedCinemas)
                == [
                    "DCF",
                    "Kino Nowe Horyzonty",
                    "Multikino Pasaż Grunwaldzki",
                    "Helios Magnolia",
                ]
        )
    }

    @Test func measuresDistanceOfEveryCinema() {
        let measuredCinemas = cinemasSortedByDistance(
            testCinemas,
            from: testUserLocation
        )

        #expect(
            measuredCinemas.allSatisfy {
                $0.distanceInMeters > 0
                    && $0.distanceInMeters != unknownDistance
            }
        )
    }

    @Test func sortsCinemasAtTheSameDistanceByName() {
        var firstCinema = testCinemaHelios
        firstCinema.distanceInMeters = 500
        var secondCinema = testCinemaDCF
        secondCinema.distanceInMeters = 500

        let sortedCinemas = [firstCinema, secondCinema].sorted(by: isCloser)

        #expect(namesOf(sortedCinemas) == ["DCF", "Helios Magnolia"])
    }

    @Test func findsPositionOfCinema() {
        #expect(
            positionOfCinema(testCinemas, cinemaId: testCinemaDCF.id) == 2
        )
        #expect(containsCinema(testCinemas, cinemaId: testCinemaDCF.id))
        #expect(
            positionOfCinema(testCinemas, cinemaId: "missing")
                == cinemaNotFound
        )
        #expect(!containsCinema(testCinemas, cinemaId: "missing"))
    }

    @Test func unknownDistanceIsEmptyText() {
        #expect(formattedDistance(unknownDistance).isEmpty)
    }

    @Test func phoneLinkHasOnlyDigits() {
        #expect(
            phoneURL(testCinemaNoweHoryzonty)?.absoluteString
                == "tel:+48717864566"
        )
        #expect(hasPhoneNumber(testCinemaNoweHoryzonty))
    }

    @Test func noPhoneOrWebsiteMeansNoLink() {
        #expect(phoneURL(testCinemaHelios) == nil)
        #expect(!hasPhoneNumber(testCinemaHelios))
        #expect(websiteURL(testCinemaHelios) == nil)
        #expect(!hasWebsite(testCinemaHelios))
    }
}

@MainActor
struct WroclawCinemasTests {
    @Test func everyCinemaIsOnTheStartMap() {
        #expect(
            wroclawCinemas.allSatisfy {
                isInRegion(cinemaCoordinate($0), wroclawMapRegion)
            }
        )
    }

    @Test func idsAreUnique() {
        let ids = wroclawCinemas.map(\.id)

        #expect(Set(ids).count == ids.count)
    }

    @Test func everyCinemaHasAddressAndWebsite() {
        #expect(
            wroclawCinemas.allSatisfy {
                !$0.address.isEmpty && hasWebsite($0)
            }
        )
    }

    @Test func pointOutsideRegionIsNotOnTheMap() {
        let outsideWroclaw = CLLocationCoordinate2D(
            latitude: 52,
            longitude: 18
        )

        #expect(!isInRegion(outsideWroclaw, wroclawMapRegion))
    }
}
