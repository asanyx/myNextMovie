import SwiftUI

/// Genre chips are the only colored element in the app.
func genreColor(_ genreId: Int) -> Color {
    switch genreId {
    case genreIdAction, genreIdWar:
        return .red
    case genreIdAdventure:
        return .green
    case genreIdAnimation, genreIdFamily, genreIdWestern:
        return .orange
    case genreIdComedy:
        return .yellow
    case genreIdCrime, genreIdThriller:
        return .teal
    case genreIdDrama, genreIdRomance:
        return .purple
    case genreIdFantasy, genreIdMystery:
        return .indigo
    case genreIdScienceFiction:
        return .blue
    case genreIdDocumentary, genreIdHistory:
        return .brown
    case genreIdMusic:
        return .pink
    default:
        return .gray
    }
}
