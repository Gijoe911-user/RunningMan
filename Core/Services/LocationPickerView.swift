//
//  LocationPickerView.swift
//  RunningMan
//
//  Composant réutilisable pour choisir un lieu de rendez-vous
//  Utilisé dans la création de sessions
//

import SwiftUI
import MapKit

/// Vue pour sélectionner un lieu de rendez-vous sur une carte
///
/// Fonctionnalités :
/// - Sélection d'un point sur la carte
/// - Recherche de lieux par nom
/// - Géolocalisation de l'utilisateur
/// - Résolution du nom à partir des coordonnées (reverse geocoding)
struct LocationPickerView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [MKMapItem] = []
    @State private var tempCoordinate: CLLocationCoordinate2D?
    @State private var tempLocationName: String = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Barre de recherche
                    searchBar
                    
                    // Carte
                    mapView
                    
                    // Informations sélectionnées
                    if !tempLocationName.isEmpty {
                        selectedLocationInfo
                    }
                    
                    // Bouton de confirmation
                    confirmButton
                }
            }
            .navigationTitle("Lieu de rendez-vous")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        Logger.log("[MAP-PICKER] ❌ Annuler pressed", category: .ui)
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            Logger.log("[MAP-PICKER] ✅ onAppear - existing: name='\(selectedLocation)', coord=\(selectedCoordinate.map { "\($0.latitude), \($0.longitude)" } ?? "nil")", category: .ui)
            // Centrer sur la localisation actuelle ou celle existante
            if let coord = selectedCoordinate {
                tempCoordinate = coord
                tempLocationName = selectedLocation
                mapPosition = .camera(
                    MapCamera(centerCoordinate: coord, distance: 1000)
                )
                Logger.log("[MAP-PICKER] 🎥 set camera to existing coord", category: .ui)
            }
        }
        .onDisappear {
            Logger.log("[MAP-PICKER] 👋 onDisappear", category: .ui)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Rechercher un lieu", text: $searchText)
                    .foregroundColor(.white)
                    .onChange(of: searchText) { _, newValue in
                        if !newValue.isEmpty {
                            isSearching = true
                            Logger.log("[MAP-PICKER] 🔎 search query: '\(newValue)'", category: .ui)
                            performSearch(query: newValue)
                        } else {
                            isSearching = false
                            searchResults = []
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        Logger.log("[MAP-PICKER] ✖️ clear search", category: .ui)
                        searchText = ""
                        searchResults = []
                        isSearching = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Bouton de géolocalisation
            Button {
                Logger.log("[MAP-PICKER] 📍 centerOnUser pressed", category: .ui)
                centerOnUserLocation()
            } label: {
                Image(systemName: "location.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        ZStack {
            Map(position: $mapPosition) {
                // Marqueur pour la position sélectionnée
                if let coord = tempCoordinate {
                    Annotation("Lieu de RDV", coordinate: coord) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.coralAccent)
                            
                            Image(systemName: "arrowtriangle.down.fill")
                                .font(.caption)
                                .foregroundColor(.coralAccent)
                                .offset(y: -5)
                        }
                    }
                }
            }
            .onTapGesture { coordinate in
                Logger.log("[MAP-PICKER] 👆 map tapped (point), handler not implemented", category: .ui)
                handleMapTap(at: coordinate)
            }
            .onChange(of: tempCoordinate?.latitude) { _, _ in
                if let c = tempCoordinate {
                    Logger.log("[MAP-PICKER] 📍 tempCoordinate changed → \(c.latitude), \(c.longitude)", category: .ui)
                }
            }
            
            // Résultats de recherche (overlay)
            if isSearching && !searchResults.isEmpty {
                VStack(spacing: 0) {
                    searchResultsList
                    Spacer()
                }
            }
        }
    }
    
    private var searchResultsList: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(searchResults, id: \.self) { item in
                    Button {
                        Logger.log("[MAP-PICKER] ✅ selectSearchResult: \(item.name ?? "unknown")", category: .ui)
                        selectSearchResult(item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Lieu inconnu")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                
                                // 🆕 iOS 26 : Utiliser addressRepresentations au lieu de placemark
                                if let address = getAddressString(from: item) {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
        .background(Color.darkNavy.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Selected Location Info
    
    private var selectedLocationInfo: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.coralAccent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Lieu sélectionné")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(tempLocationName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top)
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        Button {
            Logger.log("[MAP-PICKER] ✅ confirmSelection pressed", category: .ui)
            confirmSelection()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Confirmer le lieu")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.coralAccent, .pinkAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .disabled(tempCoordinate == nil)
        .opacity(tempCoordinate == nil ? 0.5 : 1.0)
    }
    
    // MARK: - Actions
    
    private func handleMapTap(at coordinate: CGPoint) {
        // TODO: Convertir le point écran en coordonnées
        // Pour l'instant, ce n'est pas directement supporté par SwiftUI Map
        // On utilise plutôt la recherche ou le long press
    }
    
    private func performSearch(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                Logger.log("[MAP-PICKER] 🔎 results: \(response.mapItems.count)", category: .ui)
                searchResults = response.mapItems
            } else if let error = error {
                Logger.logError(error, context: "performSearch", category: .ui)
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        // Obtenir les coordonnées de manière compatible toutes versions
        let coordinate: CLLocationCoordinate2D
        let locationName: String
        
        if #available(iOS 26.0, *) {
            // iOS 26+ : Utiliser les nouvelles APIs
            coordinate = item.location.coordinate
            locationName = item.name ?? "Lieu sélectionné"
        } else {
            // iOS < 26 : Utiliser placemark (ancien comportement)
            coordinate = item.placemark.coordinate
            locationName = item.name ?? item.placemark.name ?? "Lieu sélectionné"
        }
        
        tempCoordinate = coordinate
        tempLocationName = locationName
        
        // Centrer sur le lieu
        mapPosition = .camera(
            MapCamera(centerCoordinate: coordinate, distance: 500)
        )
        
        // Fermer la recherche
        isSearching = false
        searchText = ""
        searchResults = []
    }
    
    private func centerOnUserLocation() {
        // TODO: Demander la permission et centrer sur l'utilisateur
        // Nécessite CLLocationManager
        Logger.log("📍 Centrage sur la position utilisateur", category: .location)
    }
    
    private func confirmSelection() {
        guard let coord = tempCoordinate else {
            Logger.log("[MAP-PICKER] ⚠️ confirmSelection sans coordonnée", category: .ui)
            return
        }
        
        selectedCoordinate = coord
        selectedLocation = tempLocationName
        Logger.log("[MAP-PICKER] ✅ confirmed → '\(selectedLocation)' @ \(coord.latitude), \(coord.longitude)", category: .ui)
        
        dismiss()
    }
    
    // MARK: - Helpers
    
    /// Extrait l'adresse d'un MKMapItem de manière compatible toutes versions
    private func getAddressString(from item: MKMapItem) -> String? {
        if #available(iOS 26.0, *) {
            if let name = item.name {
                return name
            }
            return "Lieu sélectionné"
        } else {
            if let name = item.placemark.name {
                return name
            }
            if let thoroughfare = item.placemark.thoroughfare {
                return thoroughfare
            }
        }
        
        return nil
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var location: String = ""
    @Previewable @State var coordinate: CLLocationCoordinate2D? = nil
    
    LocationPickerView(
        selectedLocation: $location,
        selectedCoordinate: $coordinate
    )
}

