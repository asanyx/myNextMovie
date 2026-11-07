/// Sample data for the first lab and SwiftUI previews.
/// A TMDB request replaces it in later labs.
func loadSampleMovies() async throws -> [Movie] {
    return sampleMovies
}

func searchSampleMovies(query: String, genreId: Int) async throws -> [Movie] {
    return filterMovies(sampleMovies, query: query, genreId: genreId)
}

let sampleMovies: [Movie] = [
    Movie(
        id: 603,
        title: "The Matrix",
        overview: "A hacker named Neo learns that the world he lives in is a simulation.",
        releaseDate: "1999-03-31",
        posterPath: nil,
        voteAverage: 8.2,
        genreIds: [genreIdAction, genreIdScienceFiction]
    ),
    Movie(
        id: 27205,
        title: "Inception",
        overview: "A thief who steals secrets from dreams is asked to plant an idea instead.",
        releaseDate: "2010-07-15",
        posterPath: nil,
        voteAverage: 8.4,
        genreIds: [genreIdAction, genreIdScienceFiction, genreIdAdventure]
    ),
    Movie(
        id: 157336,
        title: "Interstellar",
        overview:
            "A team of astronauts travels through a wormhole to find a new home for humanity.",
        releaseDate: "2014-11-05",
        posterPath: nil,
        voteAverage: 8.4,
        genreIds: [genreIdAdventure, genreIdDrama, genreIdScienceFiction]
    ),
    Movie(
        id: 680,
        title: "Pulp Fiction",
        overview: "Several intertwined stories from the Los Angeles criminal underworld.",
        releaseDate: "1994-09-10",
        posterPath: nil,
        voteAverage: 8.5,
        genreIds: [genreIdThriller, genreIdCrime]
    ),
    Movie(
        id: 129,
        title: "Spirited Away",
        overview: "Ten-year-old Chihiro wanders into a world of spirits and must save her parents.",
        releaseDate: "2001-07-20",
        posterPath: nil,
        voteAverage: 8.5,
        genreIds: [genreIdAnimation, genreIdFamily, genreIdFantasy]
    ),
]
