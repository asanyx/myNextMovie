import Foundation

typealias AccountRequest = (_ email: String, _ password: String) async throws -> String

struct AccountService {
    let signedInEmail: @MainActor () -> String
    let signIn: AccountRequest
    let signUp: AccountRequest
    let signOut: () async throws -> Void
}

struct SavedMoviesCloud {
    let fetchMovies: () async throws -> [CloudSavedMovie]
    let uploadMovies: (_ cloudMovies: [CloudSavedMovie]) async throws -> Void
    let removeMovie: (_ movieId: Int) async throws -> Void
}
