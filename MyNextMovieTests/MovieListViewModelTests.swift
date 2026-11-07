import Testing

@testable import MyNextMovie

@MainActor
struct MovieListViewModelTests {
    @Test func startsIdle() {
        let viewModel = MovieListViewModel(loadMovies: { [] })

        #expect(viewModel.state == .idle)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func loadsMovies() async {
        let viewModel = MovieListViewModel(loadMovies: { sampleMovies })

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies == sampleMovies)
    }

    @Test func showsErrorWhenLoadingFails() async {
        let viewModel = MovieListViewModel(loadMovies: { throw NoConnection() })

        await viewModel.load()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    @Test
    func loadIfNeededLoadsOnlyOnce() async {
        var callCount = 0
        let viewModel = MovieListViewModel {
            callCount += 1
            return []
        }

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(callCount == 1)
    }
}
