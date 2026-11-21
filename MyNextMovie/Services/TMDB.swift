import Foundation
import SwiftData

let tmdbScheme = "https"
let tmdbHost = "api.themoviedb.org"

let tmdbPopularPath = "/3/movie/popular"
let tmdbSearchPath = "/3/search/movie"
let tmdbDiscoverPath = "/3/discover/movie"
let tmdbMoviePath = "/3/movie/"
let tmdbPathDiscoverMovies = "/3/discover/movie"
let tmdbPathSearchPeople = "/3/search/person"
let tmdbPathSearchKeywords = "/3/search/keyword"
nonisolated let noTMDBId = 0

let tmdbPeopleParameter = "with_people"
let tmdbKeywordsParameter = "with_keywords"
let tmdbReleaseDateFromParameter = "primary_release_date.gte"
let tmdbReleaseDateToParameter = "primary_release_date.lte"

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

nonisolated struct TMDBRequest: Equatable {
    let path: String
    let parameters: [URLQueryItem]
}

typealias TMDBFetch = @MainActor (_ request: TMDBRequest) async throws -> Data

private nonisolated struct TMDBIdResult: Decodable {
    let id: Int
}

private nonisolated struct TMDBIdPage: Decodable {
    let results: [TMDBIdResult]
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

func fetchTMDBRequest(_ request: TMDBRequest) async throws -> Data {
    let apiKey = try requireTMDBAPIKey()
    let address = tmdbURL(
        path: request.path,
        parameters: request.parameters,
        apiKey: apiKey
    )
    return try await fetchTMDBData(address)
}

func searchTMDBMoviesByFilters(_ filters: MovieFilters) async throws -> [Movie] {
    try await searchMoviesByFilters(filters, fetch: fetchTMDBRequest)
}

func searchMoviesByFilters(
    _ filters: MovieFilters,
    fetch: @escaping TMDBFetch
) async throws -> [Movie] {
    if !filters.title.isEmpty {
        let request = tmdbNameSearchRequest(path: tmdbSearchPath, name: filters.title)
        let movies = try decodeTMDBMovies(await fetch(request))
        return moviesMatchingFilters(movies, filters)
    }

    async let personIds = resolveTMDBIds(
        names: filters.people,
        path: tmdbPathSearchPeople,
        fetch: fetch
    )
    async let keywordIds = resolveTMDBIds(
        names: filters.keywords,
        path: tmdbPathSearchKeywords,
        fetch: fetch
    )

    let (resolvedPeople, resolvedKeywords) = try await (personIds, keywordIds)
    if resolvedPeople.count != filters.people.count {
        return []
    }

    let request = tmdbDiscoverRequest(
        filters,
        personIds: resolvedPeople,
        keywordIds: resolvedKeywords
    )
    guard !request.parameters.isEmpty else {
        return []
    }
    return try decodeTMDBMovies(await fetch(request))
}

func tmdbDiscoverRequest(
    _ filters: MovieFilters,
    personIds: [Int],
    keywordIds: [Int]
) -> TMDBRequest {
    var parameters: [URLQueryItem] = []
    if !filters.genreIds.isEmpty {
        parameters.append(
            URLQueryItem(
                name: tmdbGenresParameter,
                value: filters.genreIds.map(String.init).joined(separator: "|")
            )
        )
    }
    if !personIds.isEmpty {
        parameters.append(
            URLQueryItem(
                name: tmdbPeopleParameter,
                value: personIds.map(String.init).joined(separator: ",")
            )
        )
    }
    if !keywordIds.isEmpty {
        parameters.append(
            URLQueryItem(
                name: tmdbKeywordsParameter,
                value: keywordIds.map(String.init).joined(separator: "|")
            )
        )
    }
    if filters.fromYear != noYear {
        parameters.append(
            URLQueryItem(
                name: tmdbReleaseDateFromParameter,
                value: "\(filters.fromYear)-01-01"
            )
        )
    }
    if filters.toYear != noYear {
        parameters.append(
            URLQueryItem(
                name: tmdbReleaseDateToParameter,
                value: "\(filters.toYear)-12-31"
            )
        )
    }
    return TMDBRequest(path: tmdbPathDiscoverMovies, parameters: parameters)
}

func tmdbNameSearchRequest(path: String, name: String) -> TMDBRequest {
    TMDBRequest(
        path: path,
        parameters: [URLQueryItem(name: tmdbQueryParameter, value: name)]
    )
}

nonisolated func decodeFirstTMDBId(_ data: Data) throws -> Int {
    try JSONDecoder().decode(TMDBIdPage.self, from: data).results.first?.id ?? noTMDBId
}

private func resolveTMDBIds(
    names: [String],
    path: String,
    fetch: @escaping TMDBFetch
) async throws -> [Int] {
    try await withThrowingTaskGroup(of: (Int, Int).self) { group in
        for (index, name) in names.enumerated() {
            group.addTask {
                let request = await tmdbNameSearchRequest(path: path, name: name)
                let data = try await fetch(request)
                return (index, try decodeFirstTMDBId(data))
            }
        }

        var indexedIds: [(Int, Int)] = []
        for try await value in group {
            indexedIds.append(value)
        }
        return
            indexedIds
            .sorted { $0.0 < $1.0 }
            .map(\.1)
            .filter { $0 != noTMDBId }
    }
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
    let apiKey = try requireTMDBAPIKey()
    let data = try await fetchTMDBData(tmdbPopularURL(apiKey: apiKey))
    return try decodeTMDBMovies(data)
}

func searchTMDBMovies(query: String, genreId: Int) async throws -> [Movie] {
    let apiKey = try requireTMDBAPIKey()
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let address = tmdbSearchURL(query: trimmedQuery, genreId: genreId, apiKey: apiKey)
    let data = try await fetchTMDBData(address)
    let movies = try decodeTMDBMovies(data)
    return filterMovies(movies, query: "", genreId: genreId)
}

func fetchMovieDetails(movieId: Int) async throws -> MovieDetails {
    let apiKey = try requireTMDBAPIKey()
    let data = try await fetchTMDBData(
        tmdbMovieDetailsURL(movieId: movieId, apiKey: apiKey)
    )
    return try decodeTMDBMovieDetails(data)
}

func loadPopularMovies(cache: ModelContext) async throws -> [Movie] {
    let data = try await fetchWithCacheFallback(cache, key: "popular") {
        let apiKey = try requireTMDBAPIKey()
        return try await fetchTMDBData(tmdbPopularURL(apiKey: apiKey))
    }
    return try decodeTMDBMovies(data)
}

func loadTMDBMovieDetails(movieId: Int, cache: ModelContext) async throws -> MovieDetails {
    let cacheKey = "movie/" + String(movieId)
    let data = try await fetchWithCacheFallback(cache, key: cacheKey) {
        let apiKey = try requireTMDBAPIKey()
        return try await fetchTMDBData(
            tmdbMovieDetailsURL(movieId: movieId, apiKey: apiKey)
        )
    }
    return try decodeTMDBMovieDetails(data)
}

func requireTMDBAPIKey() throws -> String {
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
