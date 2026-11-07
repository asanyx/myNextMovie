import SwiftUI

private let chipVerticalPadding: CGFloat = 6
private let unselectedChipBackgroundOpacity = 0.15

struct GenreChip: View {
    let genreId: Int
    var isSelected = false

    var body: some View {
        let chipColor = genreColor(genreId)
        let unselectedBackground = chipColor.opacity(unselectedChipBackgroundOpacity)

        Label(genreName(genreId), systemImage: genreSymbolName(genreId))
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, spacingMedium)
            .padding(.vertical, chipVerticalPadding)
            .foregroundStyle(isSelected ? Color.white : chipColor)
            .background(isSelected ? chipColor : unselectedBackground, in: Capsule())
    }
}

#Preview {
    HStack {
        GenreChip(genreId: genreIdScienceFiction)
        GenreChip(genreId: genreIdScienceFiction, isSelected: true)
    }
}
