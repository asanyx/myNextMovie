import SwiftUI

struct SignInView: View {
    @Bindable var viewModel: AccountViewModel

    var body: some View {
        Form {
            SignInHeader()
            SignInFields(viewModel: viewModel)
            SignInActions(viewModel: viewModel)
            SignInStatus(viewModel: viewModel)
        }
    }
}

private struct SignInHeader: View {
    var body: some View {
        Section {
            VStack(spacing: spacingMedium) {
                Image(systemName: symbolNameMovies)
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text("My Next Movie")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Sign in to keep your saved movies available on your account.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, spacingLarge)
        }
    }
}

private struct SignInFields: View {
    @Bindable var viewModel: AccountViewModel

    var body: some View {
        Section {
            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .onSubmit {
                    guard viewModel.canSignIn else {
                        return
                    }
                    Task {
                        await viewModel.signIn()
                    }
                }
        }
    }
}

private struct SignInActions: View {
    let viewModel: AccountViewModel

    var body: some View {
        Section {
            Button("Sign In") {
                Task {
                    await viewModel.signIn()
                }
            }
            .disabled(!viewModel.canSignIn)

            Button("Create Account") {
                Task {
                    await viewModel.signUp()
                }
            }
            .disabled(!viewModel.canSignUp)
        }
    }
}

private struct SignInStatus: View {
    let viewModel: AccountViewModel

    var body: some View {
        Section {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .failed:
                Text(viewModel.errorMessage)
                    .foregroundStyle(.red)
            default:
                if viewModel.isWaitingForEmailConfirmation {
                    Text(
                        """
                        Check your email and open the confirmation link to finish                         creating your account.
                        """
                    )
                } else {
                    Text(
                        """
                        Passwords for new accounts need at least                         \(minimumPasswordLength) characters.
                        """
                    )
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SignInView(viewModel: previewAccountViewModel(signedInEmail: ""))
}
