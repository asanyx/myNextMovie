import MapKit
import SwiftUI

enum CinemaMapPlacement {
    case tab
    case sheet
}

struct CinemaMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CinemaMapViewModel
    @State private var cameraPosition: MapCameraPosition

    let findRoute: CinemaRouteFinder
    let placement: CinemaMapPlacement

    init(
        viewModel: CinemaMapViewModel,
        findRoute: @escaping CinemaRouteFinder,
        placement: CinemaMapPlacement
    ) {
        _viewModel = State(initialValue: viewModel)
        _cameraPosition = State(
            initialValue: .region(viewModel.visibleRegion)
        )
        self.findRoute = findRoute
        self.placement = placement
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        let mapSelection = Binding<String?>(
            get: {
                viewModel.selectedCinemaId == noCinemaSelected
                    ? nil
                    : viewModel.selectedCinemaId
            },
            set: { cinemaId in
                viewModel.selectedCinemaId = cinemaId ?? noCinemaSelected
            }
        )

        NavigationStack {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    Map(
                        position: $cameraPosition,
                        selection: mapSelection
                    ) {
                        UserAnnotation()
                        ForEach(viewModel.cinemas) { cinema in
                            Marker(
                                cinema.name,
                                systemImage: symbolNameCinema,
                                coordinate: cinemaCoordinate(cinema)
                            )
                            .tag(cinema.id)
                        }
                    }
                    .mapStyle(
                        .standard(
                            emphasis: .muted,
                            pointsOfInterest: .excludingAll
                        )
                    )
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                    }
                    .containerRelativeFrame(.vertical) { length, _ in
                        length * 0.45
                    }

                    if viewModel.isLocationUnavailable {
                        LocationUnavailableView()
                    }

                    CinemaList(
                        cinemas: viewModel.cinemas,
                        selectedCinemaId: viewModel.selectedCinemaId,
                        selectCinema: selectCinema
                    )
                }
                .onChange(of: viewModel.selectedCinemaId) { _, cinemaId in
                    guard cinemaId != noCinemaSelected else {
                        return
                    }
                    withAnimation {
                        proxy.scrollTo(cinemaId, anchor: .center)
                    }
                }
            }
            .navigationTitle("Cinemas")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Cinema.self) { cinema in
                CinemaOverviewView(cinema: cinema)
            }
            .toolbar {
                if placement == .sheet {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.locateUserIfNeeded()
            cameraPosition = .region(viewModel.visibleRegion)
        }
    }

    private func selectCinema(_ cinema: Cinema) {
        viewModel.toggleCinema(cinema)
        cameraPosition = .region(
            regionMoved(viewModel.visibleRegion, to: cinemaCoordinate(cinema))
        )
    }
}

private struct LocationUnavailableView: View {
    var body: some View {
        Label(
            "Turn on location to see distances and routes.",
            systemImage: symbolNameLocationOff
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.vertical, spacingSmall)
    }
}

private struct CinemaList: View {
    let cinemas: [Cinema]
    let selectedCinemaId: String
    let selectCinema: (Cinema) -> Void

    var body: some View {
        List(cinemas) { cinema in
            CinemaRow(
                cinema: cinema,
                isSelected: cinema.id == selectedCinemaId,
                selectCinema: selectCinema
            )
            .id(cinema.id)
        }
        .listStyle(.plain)
    }
}

private struct CinemaRow: View {
    let cinema: Cinema
    let isSelected: Bool
    let selectCinema: (Cinema) -> Void

    var body: some View {
        HStack(spacing: spacingMedium) {
            Button {
                selectCinema(cinema)
            } label: {
                VStack(alignment: .leading, spacing: spacingExtraSmall) {
                    Text(cinema.name)
                        .font(.headline)
                    Text(cinema.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !formattedDistance(cinema.distanceInMeters).isEmpty {
                        Text(formattedDistance(cinema.distanceInMeters))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            NavigationLink(value: cinema) {
                Image(systemName: symbolNameDetails)
                    .imageScale(.large)
            }
            .accessibilityLabel("Cinema details")
        }
        .listRowBackground(
            isSelected ? Color.accentColor.opacity(0.12) : Color.clear
        )
    }
}

private struct CinemaOverviewView: View {
    let cinema: Cinema

    var body: some View {
        List {
            Section {
                Text(cinema.address)
                let distance = formattedDistance(cinema.distanceInMeters)
                if !distance.isEmpty {
                    Text(distance)
                }
            }
        }
        .navigationTitle(cinema.name)
    }
}

#Preview {
    CinemaMapView(
        viewModel: CinemaMapViewModel(
            cinemas: wroclawCinemas,
            findUserLocation: { fallbackUserLocation }
        ),
        findRoute: { _, _, _ in noRoute },
        placement: .tab
    )
}
