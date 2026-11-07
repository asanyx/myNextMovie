import Foundation

// Keys from `Config/Secrets.xcconfig`, passed in through `Config/Info.plist`.
// A missing key is an empty string, so the app still builds without one.

// Key names in Config/Info.plist.
private let infoPlistKeyTMDBAPIKey = "TMDBAPIKey"
private let infoPlistKeySupabaseURL = "SupabaseURL"
private let infoPlistKeySupabaseAnonKey = "SupabaseAnonKey"

func tmdbAPIKey() -> String {
    return infoPlistValue(forKey: infoPlistKeyTMDBAPIKey)
}

func supabaseURL() -> String {
    return infoPlistValue(forKey: infoPlistKeySupabaseURL)
}

func supabaseAnonKey() -> String {
    return infoPlistValue(forKey: infoPlistKeySupabaseAnonKey)
}

private func infoPlistValue(forKey infoPlistKey: String) -> String {
    let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String
    return infoPlistValue ?? ""
}
