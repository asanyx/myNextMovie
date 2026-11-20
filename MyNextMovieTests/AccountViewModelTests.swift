import Testing

@testable import MyNextMovie

@MainActor
private final class TestAccount {
    var signedInEmail = ""
    var isOffline = false
    var needsEmailConfirmation = false
    var syncCallCount = 0
    var clearCallCount = 0
    var submittedEmail = ""
    var events: [String] = []

    var service: AccountService {
        return AccountService(
            signedInEmail: { self.signedInEmail },
            signIn: { email, _ in
                self.submittedEmail = email
                if self.isOffline {
                    throw NoConnection()
                }
                self.signedInEmail = email
                return email
            },
            signUp: { email, _ in
                self.submittedEmail = email
                if self.isOffline {
                    throw NoConnection()
                }
                if self.needsEmailConfirmation {
                    return ""
                }
                self.signedInEmail = email
                return email
            },
            signOut: {
                self.events.append("signOut")
                self.signedInEmail = ""
            }
        )
    }

    func makeViewModel() -> AccountViewModel {
        return AccountViewModel(
            account: service,
            syncSavedMovies: {
                self.syncCallCount += 1
                self.events.append("sync")
                if self.isOffline {
                    throw NoConnection()
                }
            },
            clearSavedMovies: {
                self.clearCallCount += 1
                self.events.append("clear")
            }
        )
    }
}

@MainActor
struct AccountViewModelTests {
    @Test func startsSignedOut() {
        let account = TestAccount()
        let viewModel = account.makeViewModel()

        #expect(!viewModel.isSignedIn)
    }

    @Test func newAccountNeedsLongEnoughPassword() {
        let account = TestAccount()
        let viewModel = account.makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "short"

        #expect(viewModel.canSignIn)
        #expect(!viewModel.canSignUp)
    }

    @Test func signInTrimsEmailClearsPasswordAndSyncs() async {
        let account = TestAccount()
        let viewModel = account.makeViewModel()
        viewModel.email = "  user@example.com  "
        viewModel.password = "password"

        await viewModel.signIn()

        #expect(account.submittedEmail == "user@example.com")
        #expect(viewModel.password.isEmpty)
        #expect(account.syncCallCount == 1)
        #expect(viewModel.isSignedIn)
    }

    @Test func showsErrorWhenSignInFails() async {
        let account = TestAccount()
        account.isOffline = true
        let viewModel = account.makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "password"

        await viewModel.signIn()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
        #expect(!viewModel.isSignedIn)
    }

    @Test func signUpSignsInWhenNoConfirmationIsNeeded() async {
        let account = TestAccount()
        let viewModel = account.makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "password"

        await viewModel.signUp()

        #expect(viewModel.isSignedIn)
        #expect(!viewModel.isWaitingForEmailConfirmation)
    }

    @Test func signUpWaitsForEmailConfirmation() async {
        let account = TestAccount()
        account.needsEmailConfirmation = true
        let viewModel = account.makeViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "password"

        await viewModel.signUp()

        #expect(viewModel.isWaitingForEmailConfirmation)
        #expect(!viewModel.isSignedIn)
    }

    @Test func userFromLastTimeIsSignedInAtOnce() {
        let account = TestAccount()
        account.signedInEmail = "returning@example.com"

        let viewModel = account.makeViewModel()

        #expect(viewModel.isSignedIn)
        #expect(viewModel.signedInEmail == "returning@example.com")
    }

    @Test func doesNotSyncWhenSignedOut() async {
        let account = TestAccount()
        let viewModel = account.makeViewModel()

        await viewModel.syncSavedMovies()

        #expect(account.syncCallCount == 0)
    }

    @Test func showsErrorWhenSyncFails() async {
        let account = TestAccount()
        account.signedInEmail = "user@example.com"
        account.isOffline = true
        let viewModel = account.makeViewModel()

        await viewModel.syncSavedMovies()

        #expect(viewModel.syncState == .failed)
        #expect(viewModel.syncErrorMessage == "No connection")
    }

    @Test func syncWorksAgainAfterFailure() async {
        let account = TestAccount()
        account.signedInEmail = "user@example.com"
        account.isOffline = true
        let viewModel = account.makeViewModel()
        await viewModel.syncSavedMovies()

        account.isOffline = false
        await viewModel.syncSavedMovies()

        #expect(viewModel.syncState == .loaded)
        #expect(account.syncCallCount == 2)
    }

    @Test func signOutSyncsThenClearsDevice() async {
        let account = TestAccount()
        account.signedInEmail = "user@example.com"
        let viewModel = account.makeViewModel()

        await viewModel.signOut()

        #expect(account.events == ["sync", "signOut", "clear"])
        #expect(account.clearCallCount == 1)
        #expect(!viewModel.isSignedIn)
    }
}
