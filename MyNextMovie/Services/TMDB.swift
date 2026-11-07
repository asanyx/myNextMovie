import Foundation

let tmdbScheme = "https"
let tmdbHost = "api.themoviedb.org"

let tmdbPopularPath = "/3/movie/popular"
let tmdbSearchPath = "/3/search/movie"
let tmdbDiscoverPath = "/3/discover/movie"
let tmdbMoviePath = "/3/movie/"

let tmdbAPIKeyParameter = "api_key"
let tmdbQueryParameter = "query"
let tmdbGenresParameter = "with_genres"
let tmdbAppendToResponseParameter = "append_to_response"
let tmdbMovieDetailsParts = "credits,videos,release_dates,watch/providers,recommendations"

let httpStatusOK = 200
let httpStatusUnauthorized = 401

private let missingAPIKeyMessage = "Missing TMDB API key. Add it to Config/Secrets.xcconfig."
private let unauthorizedMessage = "TMDB rejected the API key. Check Config/Secrets.xcconfig."
private let invalidAddressMessage = "Could not create the TMDB request URL."
private let invalidResponseMessage = "TMDB returned an invalid response."

nonisolated struct TMDBMoviePage: Decodable, Equatable {
    let results: [Movie]
}

nonisolated struct TMDBError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

func tmdbURL(path: String, parameters: [URLQueryItem], apiKey: String) -> URL? {
    var components = URLComponents()
    components.scheme = tmdbScheme
    components.host = tmdbHost
    components.path = path
    components.queryItems =
        [
            URLQueryItem(name: tmdbAPIKeyParameter, value: apiKey)
        ] + parameters
    return components.url
}

func tmdbPopularURL(apiKey: String) -> URL? {
    tmdbURL(path: tmdbPopularPath, parameters: [], apiKey: apiKey)
}

func tmdbSearchURL(query: String, genreId: Int, apiKey: String) -> URL? {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedQuery.isEmpty {
        return tmdbURL(
            path: tmdbDiscoverPath,
            parameters: [URLQueryItem(name: tmdbGenresParameter, value: String(genreId))],
            apiKey: apiKey
        )
    }

    return tmdbURL(
        path: tmdbSearchPath,
        parameters: [URLQueryItem(name: tmdbQueryParameter, value: trimmedQuery)],
        apiKey: apiKey
    )
}

func tmdbMovieDetailsURL(movieId: Int, apiKey: String) -> URL? {
    tmdbURL(
        path: tmdbMoviePath + String(movieId),
        parameters: [
            URLQueryItem(
                name: tmdbAppendToResponseParameter,
                value: tmdbMovieDetailsParts
            )
        ],
        apiKey: apiKey
    )
}

nonisolated func decodeTMDBMovies(_ data: Data) throws -> [Movie] {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(TMDBMoviePage.self, from: data).results
}

nonisolated func decodeTMDBMovieDetails(_ data: Data) throws -> MovieDetails {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(MovieDetails.self, from: data)
}

func checkTMDBResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw TMDBError(message: invalidResponseMessage)
    }
    if httpResponse.statusCode == httpStatusUnauthorized {
        throw TMDBError(message: unauthorizedMessage)
    }
    if httpResponse.statusCode != httpStatusOK {
        throw TMDBError(message: "TMDB request failed with HTTP status \(httpResponse.statusCode).")
    }
}

func fetchPopularMovies() async throws -> [Movie] {
    let apiKey = try requiredTMDBAPIKey()
    let data = try await fetchTMDBData(tmdbPopularURL(apiKey: apiKey))
    return try decodeTMDBMovies(data)
}

func searchTMDBMovies(query: String, genreId: Int) async throws -> [Movie] {
    let apiKey = try requiredTMDBAPIKey()
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let address = tmdbSearchURL(query: trimmedQuery, genreId: genreId, apiKey: apiKey)
    let data = try await fetchTMDBData(address)
    let movies = try decodeTMDBMovies(data)
    return filterMovies(movies, query: "", genreId: genreId)
}

func fetchMovieDetails(movieId: Int) async throws -> MovieDetails {
    let apiKey = try requiredTMDBAPIKey()
    let data = try await fetchTMDBData(
        tmdbMovieDetailsURL(movieId: movieId, apiKey: apiKey)
    )
    return try decodeTMDBMovieDetails(data)
}

private func requiredTMDBAPIKey() throws -> String {
    let apiKey = tmdbAPIKey().trimmingCharacters(in: .whitespacesAndNewlines)
    guard !apiKey.isEmpty else {
        throw TMDBError(message: missingAPIKeyMessage)
    }
    return apiKey
}

private func fetchTMDBData(_ address: URL?) async throws -> Data {
    guard let address else {
        throw TMDBError(message: invalidAddressMessage)
    }
    let (data, response) = try await URLSession.shared.data(from: address)
    try checkTMDBResponse(response)
    return data
}
