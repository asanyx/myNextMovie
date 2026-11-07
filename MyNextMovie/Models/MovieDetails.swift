import Foundation

private let directorJob = "Director"
private let youtubeSite = "YouTube"
private let trailerType = "Trailer"
private let youtubeWatchAddress = "https://www.youtube.com/watch"
private let tmdbProfileBaseURL = "https://image.tmdb.org/t/p/w185"
private let tmdbProviderLogoBaseURL = "https://image.tmdb.org/t/p/w92"

nonisolated struct MovieDetails: Decodable, Equatable {
    let id: Int
    let tagline: String
    let runtime: Int?
    let credits: Credits
    let videos: VideoList
    let releaseDates: ReleaseDateList
    let watchProviders: WatchProviderList
    let recommendations: TMDBMoviePage

    enum CodingKeys: String, CodingKey {
        case id
        case tagline
        case runtime
        case credits
        case videos
        case releaseDates
        case watchProviders = "watch/providers"
        case recommendations
    }
}

nonisolated struct Credits: Decodable, Equatable {
    let cast: [CastMember]
    let crew: [CrewMember]
}

nonisolated struct CastMember: Decodable, Equatable, Identifiable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
}

nonisolated struct CrewMember: Decodable, Equatable {
    let id: Int
    let name: String
    let job: String
}

nonisolated struct VideoList: Decodable, Equatable {
    let results: [Video]
}

nonisolated struct Video: Decodable, Equatable {
    let key: String
    let site: String
    let type: String
    let official: Bool
}

nonisolated struct ReleaseDateList: Decodable, Equatable {
    let results: [CountryReleaseDates]
}

nonisolated struct CountryReleaseDates: Decodable, Equatable {
    let countryCode: String
    let releaseDates: [ReleaseDate]

    enum CodingKeys: String, CodingKey {
        case countryCode = "iso31661"
        case releaseDates
    }
}

nonisolated struct ReleaseDate: Decodable, Equatable {
    let certification: String
}

nonisolated struct WatchProviderList: Decodable, Equatable {
    let results: [String: CountryWatchProviders]
}

nonisolated struct CountryWatchProviders: Decodable, Equatable {
    let link: String
    let flatrate: [WatchProvider]?
    let rent: [WatchProvider]?
    let buy: [WatchProvider]?
}

nonisolated struct WatchProvider: Decodable, Equatable, Identifiable {
    let providerId: Int
    let providerName: String
    let logoPath: String?

    var id: Int {
        providerId
    }
}

let emptyMovieDetails = MovieDetails(
    id: 0,
    tagline: "",
    runtime: nil,
    credits: Credits(cast: [], crew: []),
    videos: VideoList(results: []),
    releaseDates: ReleaseDateList(results: []),
    watchProviders: WatchProviderList(results: [:]),
    recommendations: TMDBMoviePage(results: [])
)

let noWatchProviders = CountryWatchProviders(
    link: "",
    flatrate: nil,
    rent: nil,
    buy: nil
)

let watchRegionCode = Locale.current.region?.identifier ?? "PL"

func formattedRuntime(_ details: MovieDetails) -> String {
    guard let runtime = details.runtime, runtime > 0 else {
        return ""
    }
    let hours = runtime / 60
    let minutes = runtime % 60
    return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
}

func directorNames(_ details: MovieDetails) -> String {
    var names: [String] = []
    var seenNames: Set<String> = []
    for crewMember in details.credits.crew where crewMember.job == directorJob {
        if seenNames.insert(crewMember.name).inserted {
            names.append(crewMember.name)
        }
    }
    return names.joined(separator: ", ")
}

func ageCertification(_ details: MovieDetails, regionCode: String) -> String {
    guard
        let country = details.releaseDates.results.first(where: {
            $0.countryCode == regionCode
        })
    else {
        return ""
    }
    return country.releaseDates.first(where: {
        !$0.certification.isEmpty
    })?.certification ?? ""
}

func trailerKey(_ details: MovieDetails) -> String {
    let trailers = details.videos.results.filter {
        $0.site == youtubeSite && $0.type == trailerType
    }
    return trailers.first(where: \.official)?.key ?? trailers.first?.key ?? ""
}

func trailerURL(_ details: MovieDetails) -> URL? {
    let key = trailerKey(details)
    guard !key.isEmpty else {
        return nil
    }
    var components = URLComponents(string: youtubeWatchAddress)
    components?.queryItems = [URLQueryItem(name: "v", value: key)]
    return components?.url
}

func hasTrailer(_ details: MovieDetails) -> Bool {
    trailerURL(details) != nil
}

func movieFactsLine(
    _ movie: Movie,
    _ details: MovieDetails,
    regionCode: String
) -> String {
    var parts = [yearAndRating(movie)]
    let runtime = formattedRuntime(details)
    let certification = ageCertification(details, regionCode: regionCode)
    if !runtime.isEmpty {
        parts.append(runtime)
    }
    if !certification.isEmpty {
        parts.append(certification)
    }
    return parts.joined(separator: textSeparator)
}

func watchProviders(
    _ details: MovieDetails,
    regionCode: String
) -> CountryWatchProviders {
    details.watchProviders.results[regionCode] ?? noWatchProviders
}

func hasWatchProviders(_ countryProviders: CountryWatchProviders) -> Bool {
    !(countryProviders.flatrate ?? []).isEmpty
        || !(countryProviders.rent ?? []).isEmpty
        || !(countryProviders.buy ?? []).isEmpty
}

func profileURL(_ castMember: CastMember) -> URL? {
    imageURL(baseAddress: tmdbProfileBaseURL, path: castMember.profilePath)
}

func logoURL(_ provider: WatchProvider) -> URL? {
    imageURL(baseAddress: tmdbProviderLogoBaseURL, path: provider.logoPath)
}

private func imageURL(baseAddress: String, path: String?) -> URL? {
    guard let path, !path.isEmpty else {
        return nil
    }
    return URL(string: baseAddress + path)
}
