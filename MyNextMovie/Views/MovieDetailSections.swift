import SwiftUI

private let castLimit = 15
private let castPhotoSize: CGFloat = 84
private let castCardWidth: CGFloat = 112
private let providerLogoSize: CGFloat = 64
private let providerCardWidth: CGFloat = 108
private let recommendationCardWidth: CGFloat = 150
private let castTextLineLimit = 2

struct MovieDetailSections: View {
    let details: MovieDetails

    var body: some View {
        VStack(alignment: .leading, spacing: spacingExtraLarge) {
            TrailerSection(details: details)
            CastSection(cast: Array(details.credits.cast.prefix(castLimit)))
            WatchProvidersSection(
                countryProviders: watchProviders(
                    details,
                    regionCode: watchRegionCode
                )
            )
            RecommendationsSection(movies: details.recommendations.results)
        }
        .padding(.horizontal)
    }
}

private struct TrailerSection: View {
    let details: MovieDetails

    var body: some View {
        if let address = trailerURL(details) {
            Link(destination: address) {
                Label("Watch Trailer", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct CastSection: View {
    let cast: [CastMember]

    var body: some View {
        if !cast.isEmpty {
            VStack(alignment: .leading, spacing: spacingMedium) {
                SectionTitle(title: "Cast")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacingMedium) {
                        ForEach(cast) { castMember in
                            CastCard(castMember: castMember)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }
}

private struct CastCard: View {
    let castMember: CastMember

    var body: some View {
        VStack(spacing: spacingSmall) {
            AsyncImage(url: profileURL(castMember)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
            .frame(width: castPhotoSize, height: castPhotoSize)
            .clipShape(Circle())

            Text(castMember.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(castTextLineLimit)
            Text(castMember.character)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(castTextLineLimit)
        }
        .multilineTextAlignment(.center)
        .frame(width: castCardWidth)
    }
}

private struct WatchProvidersSection: View {
    let countryProviders: CountryWatchProviders

    var body: some View {
        if hasWatchProviders(countryProviders) {
            VStack(alignment: .leading, spacing: spacingMedium) {
                SectionTitle(title: "Where to Watch")
                ProviderGroup(title: "Stream", providers: countryProviders.flatrate ?? [])
                ProviderGroup(title: "Rent", providers: countryProviders.rent ?? [])
                ProviderGroup(title: "Buy", providers: countryProviders.buy ?? [])
                Text("Streaming data from JustWatch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ProviderGroup: View {
    let title: String
    let providers: [WatchProvider]

    var body: some View {
        if !providers.isEmpty {
            VStack(alignment: .leading, spacing: spacingSmall) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacingMedium) {
                        ForEach(providers) { provider in
                            ProviderCard(provider: provider)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }
}

private struct ProviderCard: View {
    let provider: WatchProvider

    var body: some View {
        VStack(spacing: spacingSmall) {
            AsyncImage(url: logoURL(provider)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Image(systemName: "play.tv")
                    .font(.title)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary)
            }
            .frame(width: providerLogoSize, height: providerLogoSize)
            .clipShape(RoundedRectangle(cornerRadius: thumbnailCornerRadius))

            Text(provider.providerName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(castTextLineLimit)
        }
        .frame(width: providerCardWidth)
    }
}

private struct RecommendationsSection: View {
    let movies: [Movie]

    var body: some View {
        if !movies.isEmpty {
            VStack(alignment: .leading, spacing: spacingMedium) {
                SectionTitle(title: "More Like This")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacingLarge) {
                        ForEach(movies) { movie in
                            RecommendedMovieLink(movie: movie)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }
}

private struct RecommendedMovieLink: View {
    let movie: Movie

    var body: some View {
        NavigationLink(value: movie) {
            MovieCardView(movie: movie)
                .frame(width: recommendationCardWidth)
        }
        .buttonStyle(.plain)
    }
}

private struct SectionTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.title2.bold())
    }
}

#Preview {
    NavigationStack {
        MovieDetailSections(details: emptyMovieDetails)
    }
}
