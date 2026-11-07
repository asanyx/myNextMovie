import Testing

@testable import MyNextMovie

@MainActor
struct MovieDetailViewModelTests {
    @Test func startsIdleWithEmptyDetails() {
        let viewModel = MovieDetailViewModel(
            movieId: 603,
            loadDetails: { _ in testMovieDetails }
        )

        #expect(viewModel.state == .idle)
        #expect(viewModel.details.credits.cast.isEmpty)
    }

    @Test func loadsDetailsOfItsMovie() async {
        var receivedMovieId = 0
        let viewModel = MovieDetailViewModel(movieId: 603) { movieId in
            receivedMovieId = movieId
            return testMovieDetails
        }

        await viewModel.load()

        #expect(receivedMovieId == 603)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.details == testMovieDetails)
    }

    @Test func showsErrorWhenLoadingFails() async {
        let viewModel = MovieDetailViewModel(movieId: 603) { _ in
            throw NoConnection()
        }

        await viewModel.load()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    @Test func loadIfNeededLoadsOnlyOnce() async {
        var callCount = 0
        let viewModel = MovieDetailViewModel(movieId: 603) { _ in
            callCount += 1
            return testMovieDetails
        }

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(callCount == 1)
    }
}
