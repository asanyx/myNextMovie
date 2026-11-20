import SwiftUI

struct AccountView: View {
    let viewModel: AccountViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Signed in as") {
                    Text(viewModel.signedInEmail)
                }
                AccountSyncSection(viewModel: viewModel)
                AccountSignOutSection(viewModel: viewModel)
            }
            .navigationTitle("Account")
        }
    }
}

private struct AccountSyncSection: View {
    let viewModel: AccountViewModel

    var body: some View {
        Section("Saved movies") {
            switch viewModel.syncState {
            case .loading:
                Label("Syncing with your account", systemImage: "arrow.triangle.2.circlepath")
            case .loaded:
                Label("In sync with your account", systemImage: "checkmark.circle")
            case .failed:
                Text(viewModel.syncErrorMessage)
                    .foregroundStyle(.red)
                Button("Try again") {
                    Task {
                        await viewModel.syncSavedMovies()
                    }
                }
            case .idle:
                Text("Ready to sync")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AccountSignOutSection: View {
    let viewModel: AccountViewModel

    var body: some View {
        Section {
            Button("Sign Out", role: .destructive) {
                Task {
                    await viewModel.signOut()
                }
            }
            Text("Your saved movies stay on your account and are removed from this device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AccountView(viewModel: previewAccountViewModel(signedInEmail: testAccountEmail))
}
