//
//  LocationPickerView.swift
//  simpleApp
//
//  Location picker with map and search functionality
//

import SwiftUI
import MapKit

struct LocationData: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: LocationData, rhs: LocationData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Interactive Map View
struct InteractiveMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedLocation: LocationData?
    var onLocationTapped: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.setRegion(region, animated: false)

        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if changed
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }

        // Update pin
        mapView.removeAnnotations(mapView.annotations)
        if let location = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: InteractiveMapView

        init(_ parent: InteractiveMapView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let locationInView = gesture.location(in: mapView)
            let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)

            parent.onLocationTapped(coordinate)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "LocationPin"

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                annotationView?.markerTintColor = UIColor(AppColors.primary)
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
    }
}

struct LocationPickerView: View {
    @Binding var locationName: String?
    @Binding var locationLatitude: Double?
    @Binding var locationLongitude: Double?
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedLocation: LocationData?
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var isReverseGeocoding = false

    var body: some View {
        NavigationView {
            ZStack {
                // Interactive Map (full screen)
                InteractiveMapView(
                    region: $region,
                    selectedLocation: $selectedLocation,
                    onLocationTapped: { coordinate in
                        handleMapTap(at: coordinate)
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    // Search bar at top
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textSecondary)

                            TextField("Search for a place", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .submitLabel(.search)
                                .onChange(of: searchText) { oldValue, newValue in
                                    // Cancel previous search task
                                    searchTask?.cancel()

                                    // Clear results if search is empty
                                    if newValue.isEmpty {
                                        searchResults = []
                                        return
                                    }

                                    // Debounce search - wait 0.3 seconds after user stops typing
                                    searchTask = Task {
                                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                        if !Task.isCancelled {
                                            await MainActor.run {
                                                searchForLocation()
                                            }
                                        }
                                    }
                                }
                                .onSubmit {
                                    searchTask?.cancel()
                                    searchForLocation()
                                }

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)

                        // Search results dropdown (attached to search bar)
                        if !searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(searchResults.prefix(5), id: \.self) { item in
                                    Button(action: {
                                        selectSearchResult(item)
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(AppColors.primary)
                                                .font(.system(size: 20))

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name ?? "Unknown")
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(AppColors.textPrimary)

                                                if let address = item.placemark.title {
                                                    Text(address)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(AppColors.textSecondary)
                                                        .lineLimit(2)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "arrow.up.left")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color.white)
                                    }

                                    if item != searchResults.prefix(5).last {
                                        Divider()
                                            .padding(.leading, 48)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                            .padding(.top, 8)
                        }
                    }
                    .padding(16)
                    .background(
                        Color.clear
                            .background(.ultraThinMaterial)
                    )

                    Spacer()

                    // Selected location info at bottom
                    if let location = selectedLocation {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primary)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(location.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.textPrimary)

                                        if isReverseGeocoding {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                    }

                                    Text("Lat: \(location.coordinate.latitude, specifier: "%.4f"), Long: \(location.coordinate.longitude, specifier: "%.4f")")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textSecondary)

                                    Text("Tap anywhere on map to adjust pin")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppColors.primary.opacity(0.7))
                                        .italic()
                                }

                                Spacer()

                                Button(action: {
                                    selectedLocation = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
                        }
                        .padding(16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    .foregroundColor(selectedLocation != nil ? AppColors.primary : AppColors.textSecondary)
                    .disabled(selectedLocation == nil)
                }
            }
        }
    }

    private func searchForLocation() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        searchRequest.region = region

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    searchResults = response.mapItems
                } else {
                    searchResults = []
                }
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let location = LocationData(
            name: item.name ?? "Unknown Location",
            coordinate: item.placemark.coordinate
        )
        selectedLocation = location

        // Update map region to center on selected location
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )

        // Clear search
        searchText = ""
        searchResults = []
    }

    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        // Immediately place pin at tapped location with temporary name
        selectedLocation = LocationData(
            name: "Selected Location",
            coordinate: coordinate
        )

        // Start reverse geocoding to get address
        reverseGeocode(coordinate: coordinate)

        // Clear search results if any
        searchText = ""
        searchResults = []
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        isReverseGeocoding = true

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isReverseGeocoding = false

                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    // Keep the temporary name if geocoding fails
                    return
                }

                if let placemark = placemarks?.first {
                    // Build address from placemark
                    var addressComponents: [String] = []

                    if let name = placemark.name {
                        addressComponents.append(name)
                    } else if let thoroughfare = placemark.thoroughfare {
                        if let subThoroughfare = placemark.subThoroughfare {
                            addressComponents.append("\(subThoroughfare) \(thoroughfare)")
                        } else {
                            addressComponents.append(thoroughfare)
                        }
                    }

                    if addressComponents.isEmpty {
                        if let locality = placemark.locality {
                            addressComponents.append(locality)
                        }
                        if let administrativeArea = placemark.administrativeArea {
                            addressComponents.append(administrativeArea)
                        }
                    }

                    let locationName = addressComponents.isEmpty ? "Dropped Pin" : addressComponents.joined(separator: ", ")

                    // Update selected location with geocoded name
                    selectedLocation = LocationData(
                        name: locationName,
                        coordinate: coordinate
                    )
                }
            }
        }
    }

    private func saveLocation() {
        guard let location = selectedLocation else { return }

        locationName = location.name
        locationLatitude = location.coordinate.latitude
        locationLongitude = location.coordinate.longitude

        dismiss()
    }
}
