import Foundation
import Supabase

let supabaseSavedMoviesTable = "saved_movies"
let supabaseMovieIdColumn = "id"
let supabaseSavedAtColumn = "saved_at"
let supabaseSavedMovieConflictKey = "user_id,id"
let minimumPasswordLength = 6
let testAccountEmail = "test@test.test"
let testAccountPassword = "test"
let supabaseFunctionMovieFilters = "movie-filters"

nonisolated struct MovieWishRequest: Encodable {
    let wish: String
}

struct SupabaseError: LocalizedError {
    let message: String

    var errorDescription: String? {
        return message
    }
}

private struct FunctionErrorAnswer: Decodable {
    let message: String
}

func functionErrorMessage(statusCode: Int, data: Data) -> String {
    if let answer = try? JSONDecoder().decode(FunctionErrorAnswer.self, from: data) {
        return answer.message
    }
    return "Supabase function failed with HTTP status \(statusCode)."
}

private let missingSupabaseKeysMessage =
    "Missing Supabase keys. Add them to Config/Secrets.xcconfig."
private var sharedSupabaseClient: SupabaseClient?

private func requireSupabaseClient() throws -> SupabaseClient {
    if let sharedSupabaseClient {
        return sharedSupabaseClient
    }

    let key = supabaseAnonKey()
    guard let url = URL(string: supabaseURL()),
        url.scheme == "https",
        url.host != nil,
        !key.isEmpty
    else {
        throw SupabaseError(message: missingSupabaseKeysMessage)
    }

    let options = SupabaseClientOptions(
        auth: .init(emitLocalSessionAsInitialSession: true)
    )
    let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: key,
        options: options
    )
    sharedSupabaseClient = client
    return client
}

func parseWishWithAI(_ wish: String) async throws -> MovieFilters {
    let client = try requireSupabaseClient()
    let options = FunctionInvokeOptions(body: MovieWishRequest(wish: wish))
    do {
        return try await client.functions.invoke(
            supabaseFunctionMovieFilters,
            options: options
        )
    } catch FunctionsError.httpError(let status, let data) {
        throw SupabaseError(
            message: functionErrorMessage(statusCode: status, data: data)
        )
    }
}

@MainActor
func supabaseSignedInEmail() -> String {
    guard let client = try? requireSupabaseClient() else {
        return ""
    }
    return client.auth.currentUser?.email ?? ""
}

func signInToSupabase(email: String, password: String) async throws -> String {
    let client = try requireSupabaseClient()
    let session = try await client.auth.signIn(email: email, password: password)
    return session.user.email ?? ""
}

func signUpToSupabase(email: String, password: String) async throws -> String {
    let client = try requireSupabaseClient()
    let response = try await client.auth.signUp(email: email, password: password)
    return response.session?.user.email ?? ""
}

func signOutOfSupabase() async throws {
    let client = try requireSupabaseClient()
    try? await client.auth.signOut()
}

let supabaseAccountService = AccountService(
    signedInEmail: supabaseSignedInEmail,
    signIn: signInToSupabase,
    signUp: signUpToSupabase,
    signOut: signOutOfSupabase
)

nonisolated struct CloudSavedMovie: Codable, Equatable {
    let id: Int
    let title: String
    let overview: String
    let releaseDate: String
    let posterPath: String?
    let voteAverage: Double
    let genreIds: [Int]
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case genreIds = "genre_ids"
        case savedAt = "saved_at"
    }
}

func fetchCloudSavedMovies() async throws -> [CloudSavedMovie] {
    let client = try requireSupabaseClient()
    let cloudMovies: [CloudSavedMovie] =
        try await client
        .from(supabaseSavedMoviesTable)
        .select()
        .order(supabaseSavedAtColumn, ascending: false)
        .execute()
        .value
    return cloudMovies
}

func uploadCloudSavedMovies(_ cloudMovies: [CloudSavedMovie]) async throws {
    if cloudMovies.isEmpty {
        return
    }

    let client = try requireSupabaseClient()
    try await client
        .from(supabaseSavedMoviesTable)
        .upsert(
            cloudMovies,
            onConflict: supabaseSavedMovieConflictKey,
            returning: .minimal,
            ignoreDuplicates: true
        )
        .execute()
}

func removeCloudSavedMovie(movieId: Int) async throws {
    let client = try requireSupabaseClient()
    try await client
        .from(supabaseSavedMoviesTable)
        .delete(returning: .minimal)
        .eq(supabaseMovieIdColumn, value: movieId)
        .execute()
}

let supabaseSavedMoviesCloud = SavedMoviesCloud(
    fetchMovies: fetchCloudSavedMovies,
    uploadMovies: uploadCloudSavedMovies,
    removeMovie: removeCloudSavedMovie
)
