@testable import MyNextMovie

@MainActor
let testCinemaNoweHoryzonty = Cinema(
    id: "nowe-horyzonty",
    name: "Kino Nowe Horyzonty",
    address: "Kazimierza Wielkiego 19a, Wrocław",
    phoneNumber: "+48 71 786 45 66",
    website: "https://kinonh.pl",
    latitude: 51.1086,
    longitude: 17.0263
)

@MainActor
let testCinemaHelios = Cinema(
    id: "helios-magnolia",
    name: "Helios Magnolia",
    address: "Legnicka 58, Wrocław",
    phoneNumber: "",
    website: "",
    latitude: 51.1188,
    longitude: 16.9906
)

@MainActor
let testCinemaDCF = Cinema(
    id: "dcf",
    name: "DCF",
    address: "Piłsudskiego 64a, Wrocław",
    phoneNumber: "",
    website: "",
    latitude: 51.1031,
    longitude: 17.0285
)

@MainActor
let testCinemaMultikino = Cinema(
    id: "multikino-pasaz",
    name: "Multikino Pasaż Grunwaldzki",
    address: "Plac Grunwaldzki 22, Wrocław",
    phoneNumber: "",
    website: "",
    latitude: 51.1123,
    longitude: 17.0602
)

@MainActor
let testCinemas = [
    testCinemaNoweHoryzonty,
    testCinemaHelios,
    testCinemaDCF,
    testCinemaMultikino,
]

/// Wrocław Główny station, where the tests pretend the user stands.
@MainActor
let testUserLocation = UserLocation(
    latitude: 51.0983,
    longitude: 17.0368,
    isKnown: true
)

@MainActor
func namesOf(_ cinemas: [Cinema]) -> [String] {
    var names: [String] = []
    for cinema in cinemas {
        names.append(cinema.name)
    }
    return names
}
