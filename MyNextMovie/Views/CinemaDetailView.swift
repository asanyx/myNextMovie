import MapKit
import SwiftUI

struct CinemaDetailView: View {
    @State private var viewModel: CinemaDetailViewModel
    @State private var lookAroundScene: MKLookAroundScene?

    init(
        cinema: Cinema,
        userLocation: UserLocation,
        findRoute: @escaping CinemaRouteFinder
    ) {
        _viewModel = State(
            initialValue: CinemaDetailViewModel(
                cinema: cinema,
                userLocation: userLocation,
                findRoute: findRoute
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            CinemaRouteMapSection(
                cinema: viewModel.cinema,
                userLocation: viewModel.userLocation,
                route: viewModel.route,
                showsRoute: viewModel.routeState == .loaded
            )
            CinemaAddressSection(cinema: viewModel.cinema)
            CinemaWayThereSection(
                travelMode: $viewModel.travelMode,
                canFindRoute: viewModel.canFindRoute,
                routeState: viewModel.routeState,
                route: viewModel.route,
                errorMessage: viewModel.errorMessage
            )
            CinemaLinksSection(
                cinema: viewModel.cinema,
                travelMode: viewModel.travelMode
            )
            if let lookAroundScene {
                CinemaLookAroundSection(scene: lookAroundScene)
            }
        }
        .navigationTitle(viewModel.cinema.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.travelMode) {
            await viewModel.loadRoute()
        }
        .task {
            lookAroundScene = await findLookAroundScene(viewModel.cinema)
        }
    }
}

private struct CinemaRouteMapSection: View {
    let cinema: Cinema
    let userLocation: UserLocation
    let route: CinemaRoute
    let showsRoute: Bool

    var body: some View {
        Section {
            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: cinemaCoordinate(cinema),
                        latitudinalMeters: 2_500,
                        longitudinalMeters: 2_500
                    )
                )
            ) {
                Marker(
                    cinema.name,
                    systemImage: symbolNameCinema,
                    coordinate: cinemaCoordinate(cinema)
                )
                if userLocation.isKnown {
                    Marker(
                        "Your Location",
                        systemImage: "location.fill",
                        coordinate: userCoordinate(userLocation)
                    )
                    .tint(.blue)
                }
                if showsRoute {
                    MapPolyline(route.line)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .mapStyle(
                .standard(
                    emphasis: .muted,
                    pointsOfInterest: .excludingAll
                )
            )
            .frame(height: 220)
            .listRowInsets(EdgeInsets())
        }
    }
}

private struct CinemaAddressSection: View {
    let cinema: Cinema

    var body: some View {
        Section {
            Label(cinema.address, systemImage: symbolNameCinema)
            let distance = formattedDistance(cinema.distanceInMeters)
            if !distance.isEmpty {
                Label(distance, systemImage: symbolNameWalking)
            }
        }
    }
}

private struct CinemaWayThereSection: View {
    @Binding var travelMode: TravelMode

    let canFindRoute: Bool
    let routeState: LoadState
    let route: CinemaRoute
    let errorMessage: String

    var body: some View {
        Section("Way There") {
            Picker("Travel mode", selection: $travelMode) {
                Label("Walk", systemImage: symbolNameWalking)
                    .tag(TravelMode.walking)
                Label("Drive", systemImage: symbolNameDriving)
                    .tag(TravelMode.driving)
            }
            .pickerStyle(.segmented)
            .disabled(!canFindRoute)

            if !canFindRoute {
                Label(
                    "Turn on location to find a route.",
                    systemImage: symbolNameLocationOff
                )
                .foregroundStyle(.secondary)
            } else {
                CinemaRouteStatus(
                    routeState: routeState,
                    route: route,
                    errorMessage: errorMessage
                )
            }
        }
    }
}

private struct CinemaRouteStatus: View {
    let routeState: LoadState
    let route: CinemaRoute
    let errorMessage: String

    var body: some View {
        switch routeState {
        case .idle:
            EmptyView()
        case .loading:
            HStack {
                ProgressView()
                Text("Finding route")
            }
        case .loaded:
            Text(routeSummary(route))
        case .failed:
            Label(errorMessage, systemImage: symbolNameError)
                .foregroundStyle(.red)
        }
    }
}

private struct CinemaLinksSection: View {
    let cinema: Cinema
    let travelMode: TravelMode

    var body: some View {
        Section {
            Button {
                openCinemaInMaps(cinema, travelMode: travelMode)
            } label: {
                Label("Directions in Maps", systemImage: symbolNameDirections)
            }

            if let address = phoneURL(cinema) {
                Link(destination: address) {
                    Label(cinema.phoneNumber, systemImage: symbolNamePhone)
                }
            }

            if let address = websiteURL(cinema) {
                Link(destination: address) {
                    Label("Website", systemImage: symbolNameWebsite)
                }
            }
        }
    }
}

private struct CinemaLookAroundSection: View {
    let scene: MKLookAroundScene

    var body: some View {
        Section("Look Around") {
            LookAroundPreview(initialScene: scene)
                .frame(height: 220)
                .listRowInsets(EdgeInsets())
        }
    }
}

#Preview {
    NavigationStack {
        CinemaDetailView(
            cinema: wroclawCinemas[0],
            userLocation: fallbackUserLocation,
            findRoute: { _, _, _ in noRoute }
        )
    }
}
