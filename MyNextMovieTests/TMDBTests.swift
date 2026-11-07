import Foundation
import Testing

@testable import MyNextMovie

private let moviePageJSON = """
    {
      "results": [
        {
          "id": 603,
          "title": "The Matrix",
          "overview": "A computer hacker learns the truth.",
          "release_date": "1999-03-31",
          "poster_path": "/matrix.jpg",
          "vote_average": 8.2,
          "genre_ids": [28, 878]
        }
      ]
    }
    """

private let movieWithoutPosterJSON = """
    {
      "results": [
        {
          "id": 1,
          "title": "No Poster",
          "overview": "",
          "release_date": "",
          "poster_path": null,
          "vote_average": 0,
          "genre_ids": []
        }
      ]
    }
    """

@MainActor
struct TMDBTests {
    @Test func decodesSnakeCaseKeys() throws {
        let movies = try decodeTMDBMovies(Data(moviePageJSON.utf8))
        let movie = try #require(movies.first)

        #expect(movie.releaseDate == "1999-03-31")
        #expect(movie.posterPath == "/matrix.jpg")
        #expect(movie.voteAverage == 8.2)
        #expect(movie.genreIds == [genreIdAction, genreIdScienceFiction])
    }

    @Test func decodesMissingPosterAsNil() throws {
        let movies = try decodeTMDBMovies(Data(movieWithoutPosterJSON.utf8))

        #expect(try #require(movies.first).posterPath == nil)
    }

    @Test func decodingFailsForOtherJSON() {
        let errorJSON = #"{"status_code": 7}"#

        #expect(throws: DecodingError.self) {
            try decodeTMDBMovies(Data(errorJSON.utf8))
        }
    }

    @Test func popularURLHasAPIKey() throws {
        let address = try #require(tmdbPopularURL(apiKey: "test-key"))

        #expect(
            address.absoluteString == "https://api.themoviedb.org/3/movie/popular?api_key=test-key")
    }

    @Test func searchWithTextUsesSearchEndpoint() throws {
        let address = try #require(
            tmdbSearchURL(query: "matrix", genreId: genreIdAction, apiKey: "test-key")
        )
        let queryItems = URLComponents(url: address, resolvingAgainstBaseURL: false)?.queryItems

        #expect(address.path() == tmdbSearchPath)
        #expect(
            queryItems?.contains(URLQueryItem(name: tmdbQueryParameter, value: "matrix")) == true)
    }

    @Test func searchWithGenreOnlyUsesDiscoverEndpoint() throws {
        let address = try #require(
            tmdbSearchURL(query: "", genreId: genreIdAnimation, apiKey: "test-key")
        )
        let queryItems = URLComponents(url: address, resolvingAgainstBaseURL: false)?.queryItems

        #expect(address.path() == tmdbDiscoverPath)
        #expect(
            queryItems?.contains(
                URLQueryItem(name: tmdbGenresParameter, value: String(genreIdAnimation))
            ) == true
        )
    }

    @Test func searchTextIsPercentEncoded() throws {
        let address = try #require(
            tmdbSearchURL(query: "pan tadeusz", genreId: noGenreId, apiKey: "test-key")
        )

        #expect(address.absoluteString.contains("query=pan%20tadeusz"))
    }

    @Test func detailsURLAppendsEveryPart() throws {
        let address = try #require(
            tmdbMovieDetailsURL(movieId: 603, apiKey: "test-key")
        )
        let queryItems = URLComponents(
            url: address,
            resolvingAgainstBaseURL: false
        )?.queryItems

        #expect(address.path() == "/3/movie/603")
        #expect(
            queryItems?.contains(
                URLQueryItem(
                    name: tmdbAppendToResponseParameter,
                    value: tmdbMovieDetailsParts
                )
            ) == true
        )
    }

    @Test func okResponsePasses() throws {
        let response = try makeHTTPResponse(statusCode: httpStatusOK)

        try checkTMDBResponse(response)
    }

    @Test func unauthorizedResponseMentionsAPIKey() throws {
        let response = try makeHTTPResponse(statusCode: httpStatusUnauthorized)
        let thrownError = #expect(throws: TMDBError.self) {
            try checkTMDBResponse(response)
        }

        #expect(thrownError?.localizedDescription.contains("API key") == true)
    }

    @Test func otherErrorResponseShowsStatus() throws {
        let response = try makeHTTPResponse(statusCode: 404)
        let thrownError = #expect(throws: TMDBError.self) {
            try checkTMDBResponse(response)
        }

        #expect(thrownError?.localizedDescription.contains("404") == true)
    }

    private func makeHTTPResponse(statusCode: Int) throws -> HTTPURLResponse {
        let address = try #require(URL(string: "https://api.themoviedb.org"))
        return try #require(
            HTTPURLResponse(
                url: address,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
        )
    }
}
