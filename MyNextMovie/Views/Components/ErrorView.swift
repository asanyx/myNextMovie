import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbolNameError)
        } description: {
            Text(message)
        } actions: {
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ErrorView(title: "Could not load movies", message: "No connection", retry: {})
}
