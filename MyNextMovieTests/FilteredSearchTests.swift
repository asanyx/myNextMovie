import Foundation
import Testing

@testable import MyNextMovie

@MainActor
struct FilteredSearchTests {
    @Test func namesBecomeIdsInOneDiscoverRequest() async throws {
        let server = TestTMDB()
        server.ids = ["Keanu Reeves": 6384, "heist": 10051]

        _ = try await searchMoviesByFilters(
            filters(people: ["Keanu Reeves"], keywords: ["heist"]),
            fetch: server.fetch
        )

        let discover = try #require(
            server.requests.first { $0.path == tmdbPathDiscoverMovies }
        )
        #expect(server.requests.filter { $0.path == tmdbPathDiscoverMovies }.count == 1)
        #expect(parameter(discover, tmdbPeopleParameter) == "6384")
        #expect(parameter(discover, tmdbKeywordsParameter) == "10051")
    }

    @Test func looksUpEveryNameAtOnce() async throws {
        let server = TestTMDB()
        server.ids = [
            "One": 1, "Two": 2, "Three": 3,
            "space": 4, "robot": 5, "future": 6,
        ]

        _ = try await searchMoviesByFilters(
            filters(
                people: ["One", "Two", "Three"],
                keywords: ["space", "robot", "future"]
            ),
            fetch: server.fetch
        )

        #expect(server.maximumActiveRequests > 1)
        #expect(
            server.requests.filter {
                $0.path == tmdbPathSearchPeople || $0.path == tmdbPathSearchKeywords
            }.count == 6
        )
    }

    @Test func unknownPersonFindsNothing() async throws {
        let server = TestTMDB()
        server.ids = ["Known": 1]

        let movies = try await searchMoviesByFilters(
            filters(genreIds: [genreIdDrama], people: ["Known", "Unknown"]),
            fetch: server.fetch
        )

        #expect(movies.isEmpty)
        #expect(!server.requests.contains { $0.path == tmdbPathDiscoverMovies })
    }

    @Test func onlyUnknownKeywordsFindNothing() async throws {
        let server = TestTMDB()

        let movies = try await searchMoviesByFilters(
            filters(keywords: ["not in TMDB"]),
            fetch: server.fetch
        )

        #expect(movies.isEmpty)
        #expect(!server.requests.contains { $0.path == tmdbPathDiscoverMovies })
    }

    @Test func unknownKeywordNextToGenreStillSearches() async throws {
        let server = TestTMDB()

        _ = try await searchMoviesByFilters(
            filters(genreIds: [genreIdAnimation], keywords: ["not in TMDB"]),
            fetch: server.fetch
        )

        let discover = try #require(
            server.requests.first { $0.path == tmdbPathDiscoverMovies }
        )
        #expect(parameter(discover, tmdbGenresParameter) == String(genreIdAnimation))
        #expect(parameter(discover, tmdbKeywordsParameter) == nil)
    }

    @Test func titleSearchKeepsYearsAndGenres() async throws {
        let server = TestTMDB()
        server.movies = [
            movie(id: 1, year: 1995, genres: [genreIdAction]),
            movie(id: 2, year: 1995, genres: [genreIdComedy]),
            movie(id: 3, year: 2005, genres: [genreIdAction]),
        ]

        let movies = try await searchMoviesByFilters(
            filters(
                genreIds: [genreIdAction],
                fromYear: 1990,
                toYear: 1999,
                title: "Matrix"
            ),
            fetch: server.fetch
        )

        #expect(movies.map(\.id) == [1])
        #expect(server.requests.count == 1)
        #expect(server.requests[0].path == tmdbSearchPath)
        #expect(parameter(server.requests[0], tmdbQueryParameter) == "Matrix")
    }
}

@MainActor
struct MoviesMatchingFiltersTests {
    @Test func withoutGenresAndYearsAllMatch() {
        let movies = [movie(id: 1), movie(id: 2)]
        #expect(moviesMatchingFilters(movies, noMovieFilters) == movies)
    }

    @Test func anyOfTheGenresMatches() {
        let movies = [
            movie(id: 1, genres: [genreIdAction]),
            movie(id: 2, genres: [genreIdDrama]),
            movie(id: 3, genres: [genreIdComedy]),
        ]
        let result = moviesMatchingFilters(
            movies,
            filters(genreIds: [genreIdAction, genreIdDrama])
        )
        #expect(result.map(\.id) == [1, 2])
    }

    @Test func movieWithoutYearDoesNotMatchYears() {
        let result = moviesMatchingFilters(
            [movie(id: 1), movie(id: 2, year: 1995)],
            filters(fromYear: 1990, toYear: 1999)
        )
        #expect(result.map(\.id) == [2])
    }

    @Test func yearsIncludeBothEnds() {
        let movies = [
            movie(id: 1, year: 1989),
            movie(id: 2, year: 1990),
            movie(id: 3, year: 1999),
            movie(id: 4, year: 2000),
        ]
        let result = moviesMatchingFilters(
            movies,
            filters(fromYear: 1990, toYear: 1999)
        )
        #expect(result.map(\.id) == [2, 3])
    }
}

@MainActor
private final class TestTMDB {
    var requests: [TMDBRequest] = []
    var ids: [String: Int] = [:]
    var movies: [Movie] = []
    var activeRequests = 0
    var maximumActiveRequests = 0

    func fetch(_ request: TMDBRequest) async throws -> Data {
        requests.append(request)
        activeRequests += 1
        maximumActiveRequests = max(maximumActiveRequests, activeRequests)
        await Task.yield()
        activeRequests -= 1

        if request.path == tmdbPathDiscoverMovies || request.path == tmdbSearchPath {
            return try moviePage(movies)
        }
        let name = parameter(request, tmdbQueryParameter) ?? ""
        if let id = ids[name] {
            return Data(#"{"results":[{"id":\#(id)}]}"#.utf8)
        }
        return Data(#"{"results":[]}"#.utf8)
    }
}

@MainActor
private func filters(
    genreIds: [Int] = [],
    fromYear: Int = noYear,
    toYear: Int = noYear,
    people: [String] = [],
    keywords: [String] = [],
    title: String = ""
) -> MovieFilters {
    MovieFilters(
        genreIds: genreIds,
        fromYear: fromYear,
        toYear: toYear,
        people: people,
        keywords: keywords,
        title: title
    )
}

@MainActor
private func movie(
    id: Int,
    year: Int? = nil,
    genres: [Int] = []
) -> Movie {
    Movie(
        id: id,
        title: "Movie \(id)",
        overview: "",
        releaseDate: year.map { "\($0)-06-15" } ?? "",
        posterPath: nil,
        voteAverage: 0,
        genreIds: genres
    )
}

private func moviePage(_ movies: [Movie]) throws -> Data {
    let results = movies.map { movie in
        [
            "id": movie.id,
            "title": movie.title,
            "overview": movie.overview,
            "release_date": movie.releaseDate,
            "poster_path": movie.posterPath as Any,
            "vote_average": movie.voteAverage,
            "genre_ids": movie.genreIds,
        ] as [String: Any]
    }
    return try JSONSerialization.data(withJSONObject: ["results": results])
}

private func parameter(_ request: TMDBRequest, _ name: String) -> String? {
    request.parameters.first { $0.name == name }?.value
}
