import SwiftUI

private let backdropHeight: CGFloat = 440
private let backdropBlurRadius: CGFloat = 40
private let posterWidthOnBackdrop: CGFloat = 200
private let posterShadowColor = Color.black.opacity(0.35)
private let posterShadowRadius: CGFloat = 20
private let posterShadowOffset: CGFloat = 10

struct MovieDetailView: View {
    let movie: Movie
    @State private var viewModel: MovieDetailViewModel

    init(movie: Movie, loadDetails: @escaping MovieDetailsLoader) {
        self.movie = movie
        _viewModel = State(
            initialValue: MovieDetailViewModel(
                movieId: movie.id,
                loadDetails: loadDetails
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacingExtraLarge) {
                MovieBackdrop(movie: movie)
                MovieInfo(movie: movie, details: viewModel.details)
                    .padding(.horizontal)
                MovieDetailLoadContent(
                    state: viewModel.state,
                    details: viewModel.details,
                    errorMessage: viewModel.errorMessage,
                    retry: {
                        Task { await viewModel.load() }
                    }
                )
            }
            .padding(.bottom, spacingHuge)
        }
        .task { await viewModel.loadIfNeeded() }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The poster, sharp, on top of itself stretched to the screen width and blurred.
private struct MovieBackdrop: View {
    let movie: Movie

    var body: some View {
        GeometryReader { geometry in
            BlurredPoster(movie: movie, backdropSize: geometry.size)
        }
        .frame(height: backdropHeight)
        .clipped()
        .overlay { fadeToBackground }
        .overlay(alignment: .bottom) { sharpPoster }
    }

    private var fadeToBackground: some View {
        LinearGradient(
            colors: [.clear, Color(.systemBackground)],
            startPoint: .center,
            endPoint: .bottom
        )
    }

    private var sharpPoster: some View {
        PosterView(movie: movie)
            .frame(width: posterWidthOnBackdrop)
            .shadow(color: posterShadowColor, radius: posterShadowRadius, y: posterShadowOffset)
    }
}

private struct BlurredPoster: View {
    let movie: Movie
    let backdropSize: CGSize

    var body: some View {
        PosterView(movie: movie, cornerRadius: 0)
            .frame(width: backdropSize.width)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: backdropSize.width, height: backdropSize.height)
            .blur(radius: backdropBlurRadius, opaque: true)
    }
}

/// Title, year and rating, genres and overview under the backdrop.
private struct MovieInfo: View {
    let movie: Movie
    let details: MovieDetails

    var body: some View {
        VStack(alignment: .leading, spacing: spacingLarge) {
            MovieHeading(movie: movie, details: details)
            GenreRow(genreIds: knownGenreIds(movie))
            MovieOverview(overview: movie.overview)
            MovieDirector(names: directorNames(details))
        }
    }
}

private struct MovieHeading: View {
    let movie: Movie
    let details: MovieDetails

    var body: some View {
        VStack(alignment: .leading, spacing: spacingSmall) {
            Text(movie.title)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
            if !details.tagline.isEmpty {
                Text(details.tagline)
                    .font(.headline.italic())
                    .foregroundStyle(.secondary)
            }
            Text(movieFactsLine(movie, details, regionCode: watchRegionCode))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MovieDirector: View {
    let names: String

    var body: some View {
        if !names.isEmpty {
            VStack(alignment: .leading, spacing: spacingSmall) {
                Text("Directed by")
                    .font(.headline)
                Text(names)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct MovieDetailLoadContent: View {
    let state: LoadState
    let details: MovieDetails
    let errorMessage: String
    let retry: () -> Void

    @ViewBuilder
    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        case .loaded:
            MovieDetailSections(details: details)
        case .failed:
            ErrorView(
                title: "Could not load details",
                message: errorMessage,
                retry: retry
            )
            .frame(minHeight: 240)
        }
    }
}

private struct MovieOverview: View {
    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: spacingSmall) {
            Text("Overview")
                .font(.headline)
            Text(overview)
                .foregroundStyle(.secondary)
        }
    }
}

/// Genre chips in one row that scrolls sideways when they do not fit.
private struct GenreRow: View {
    let genreIds: [Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacingSmall) {
                ForEach(genreIds, id: \.self) { genreId in
                    GenreChip(genreId: genreId)
                }
            }
        }
        .scrollClipDisabled()
    }
}

#Preview {
    NavigationStack {
        MovieDetailView(movie: sampleMovies[0], loadDetails: { _ in emptyMovieDetails })
    }
}
