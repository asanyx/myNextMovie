import Foundation
import Observation

@Observable
final class AccountViewModel {
    var email = ""
    var password = ""
    private(set) var signedInEmail: String
    private(set) var state = LoadState.idle
    private(set) var errorMessage = ""
    private(set) var isWaitingForEmailConfirmation = false
    private(set) var syncState = LoadState.idle
    private(set) var syncErrorMessage = ""

    private let account: AccountService
    private let performSavedMoviesSync: () async throws -> Void
    private let clearSavedMovies: @MainActor () -> Void
    private var isAnotherSyncRequested = false

    init(
        account: AccountService,
        syncSavedMovies: @escaping () async throws -> Void,
        clearSavedMovies: @escaping @MainActor () -> Void
    ) {
        self.account = account
        performSavedMoviesSync = syncSavedMovies
        self.clearSavedMovies = clearSavedMovies
        signedInEmail = account.signedInEmail()
    }

    var isSignedIn: Bool {
        return !signedInEmail.isEmpty
    }

    var canSignIn: Bool {
        return !trimmedEmail.isEmpty && !password.isEmpty && state != .loading
    }

    var canSignUp: Bool {
        return canSignIn && password.count >= minimumPasswordLength
    }

    func signIn() async {
        await submit(account.signIn)
    }

    func signUp() async {
        await submit(account.signUp)
    }

    func syncSavedMovies() async {
        guard isSignedIn else {
            return
        }

        if syncState == .loading {
            isAnotherSyncRequested = true
            return
        }

        repeat {
            isAnotherSyncRequested = false
            syncState = .loading
            syncErrorMessage = ""

            do {
                try await performSavedMoviesSync()
                syncState = .loaded
            } catch {
                syncErrorMessage = error.localizedDescription
                syncState = .failed
            }
        } while isAnotherSyncRequested
    }

    func signOut() async {
        await syncSavedMovies()

        do {
            try await account.signOut()
            signedInEmail = ""
            clearSavedMovies()
            state = .idle
            syncState = .idle
        } catch {
            errorMessage = error.localizedDescription
            state = .failed
        }
    }

    private var trimmedEmail: String {
        return email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func submit(_ request: AccountRequest) async {
        state = .loading
        errorMessage = ""
        isWaitingForEmailConfirmation = false

        do {
            let returnedEmail = try await request(trimmedEmail, password)
            password = ""
            signedInEmail = returnedEmail
            state = .loaded

            if returnedEmail.isEmpty {
                isWaitingForEmailConfirmation = true
            } else {
                await syncSavedMovies()
            }
        } catch {
            errorMessage = error.localizedDescription
            state = .failed
        }
    }
}

@MainActor
func previewAccountViewModel(signedInEmail: String) -> AccountViewModel {
    let account = AccountService(
        signedInEmail: { signedInEmail },
        signIn: { email, _ in email },
        signUp: { email, _ in email },
        signOut: {}
    )
    return AccountViewModel(
        account: account,
        syncSavedMovies: {},
        clearSavedMovies: {}
    )
}
