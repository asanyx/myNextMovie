import Foundation
import Supabase

let supabaseSavedMoviesTable = "saved_movies"
let supabaseMovieIdColumn = "id"
let supabaseSavedAtColumn = "saved_at"
let supabaseSavedMovieConflictKey = "user_id,id"
let minimumPasswordLength = 6
let testAccountEmail = "test@test.test"
let testAccountPassword = "test"

struct SupabaseError: LocalizedError {
    let message: String

    var errorDescription: String? {
        return message
    }
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

    let client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    sharedSupabaseClient = client
    return client
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
