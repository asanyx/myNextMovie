import MapKit

/// The cinemas of Wrocław, written out like `genreTable`, so the map shows them at once,
/// without a network request. Positions, addresses and phone numbers come from Apple Maps.
/// A search in MapKit (`MKLocalSearch`) also returns theaters, film companies and cinemas
/// from other cities, so the app keeps its own list.
let wroclawCinemas: [Cinema] = [
    Cinema(
        id: "nowe-horyzonty",
        name: "Kino Nowe Horyzonty",
        address: "Kazimierza Wielkiego 19A-21, Wrocław",
        phoneNumber: "+48 532 726 581",
        website: "https://www.kinonh.pl",
        latitude: 51.10930,
        longitude: 17.02612
    ),
    Cinema(
        id: "dcf",
        name: "Kino DCF",
        address: "Marszałka J. Piłsudskiego 64A, Wrocław",
        phoneNumber: "+48 71 796 34 87",
        website: "https://www.dcf.wroclaw.pl",
        latitude: 51.10167,
        longitude: 17.03036
    ),
    Cinema(
        id: "cinema-city-wroclavia",
        name: "Cinema City Wroclavia",
        address: "Sucha 1, Wrocław",
        phoneNumber: "+48 71 306 80 68",
        website: "https://www.cinema-city.pl/kina/wroclavia",
        latitude: 51.09644,
        longitude: 17.03389
    ),
    Cinema(
        id: "cinema-city-korona",
        name: "Cinema City Korona",
        address: "Bolesława Krzywoustego 126C, Wrocław",
        phoneNumber: "",
        website: "https://www.cinema-city.pl/kina/korona",
        latitude: 51.14184,
        longitude: 17.08734
    ),
    Cinema(
        id: "multikino-pasaz-grunwaldzki",
        name: "Multikino Pasaż Grunwaldzki",
        address: "Plac Grunwaldzki 22, Wrocław",
        phoneNumber: "+48 54 230 36 36",
        website: "https://multikino.pl/repertuar/wroclaw-pasaz-grunwaldzki",
        latitude: 51.11235,
        longitude: 17.05933
    ),
    Cinema(
        id: "helios-magnolia",
        name: "Helios Magnolia",
        address: "Legnicka 58, Wrocław",
        phoneNumber: "+48 71 355 53 54",
        website: "https://www.helios.pl/3,Wroclaw/StronaGlowna",
        latitude: 51.11820,
        longitude: 16.98720
    ),
    Cinema(
        id: "helios-aleja-bielany",
        name: "Helios Aleja Bielany",
        address: "Czekoladowa 7, Bielany Wrocławskie",
        phoneNumber: "+48 71 712 10 42",
        website: "https://www.helios.pl/48,Wroclaw/StronaGlowna",
        latitude: 51.04935,
        longitude: 16.95869
    ),
]
