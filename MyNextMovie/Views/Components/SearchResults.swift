import SwiftUI

private let searchResultThumbnailWidth: CGFloat = 56
private let searchResultTitleMaxLines = 2

/// Found movies as a list, or a "no results" message when nothing matches.
struct SearchResults: View {
    let movies: [Movie]
    let query: String

    var body: some View {
        if movies.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List(movies) { movie in
                SearchResultRow(movie: movie)
            }
            .listStyle(.plain)
        }
    }
}

/// One found movie: a small poster on the left, the title, subtitle and rating on the right.
/// Tapping it opens the movie details.
struct SearchResultRow: View {
    let movie: Movie

    var body: some View {
        NavigationLink(value: movie) {
            HStack(spacing: spacingMedium) {
                PosterView(movie: movie, cornerRadius: thumbnailCornerRadius)
                    .frame(width: searchResultThumbnailWidth)

                VStack(alignment: .leading, spacing: spacingExtraSmall) {
                    Text(movie.title)
                        .font(.headline)
                        .lineLimit(searchResultTitleMaxLines)
                    Text(movieSubtitle(movie))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(ratingWithStar(movie))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, spacingExtraSmall)
        }
    }
}
