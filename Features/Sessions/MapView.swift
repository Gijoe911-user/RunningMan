//
//  MapView.swift
//  RunningMan
//
//  Vue Map avec annotations des coureurs
//

import SwiftUI
import MapKit

struct MapView: View {
    let runnerLocations: [RunnerLocation]
    let userLocation: CLLocationCoordinate2D?
    let routePoints: [RoutePoint]  // Nouveaux: points du parcours
    @Binding var mapPosition: MapCameraPosition
    
    // Créer une version Equatable de la coordonnée pour onChange
    private var equatableLocation: EquatableCoordinate? {
        guard let location = userLocation else { return nil }
        return EquatableCoordinate(latitude: location.latitude, longitude: location.longitude)
    }
    
    var body: some View {
        Map(position: $mapPosition) {
            // Show user location
            UserAnnotation()
            
            // Show runner annotations
            ForEach(runnerLocations) { runner in
                Annotation("", coordinate: runner.coordinate) {
                    RunnerMapAnnotation(runner: runner)
                }
            }
            
            // Show route polyline
            if routePoints.count > 1 {
                MapPolyline(coordinates: routePoints.map { $0.coordinate })
                    .stroke(Color.coralAccent, lineWidth: 3)
            }
        }
        .onChange(of: equatableLocation) { oldValue, newValue in
            // Ne centrer automatiquement que si aucune position spécifique n'est définie
            guard let newLocation = newValue else { return }
            
            // Vérifier si la position actuelle est .automatic
            if case .automatic = mapPosition {
                withAnimation {
                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(
                                latitude: newLocation.latitude,
                                longitude: newLocation.longitude
                            ),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Equatable Coordinate Wrapper
struct EquatableCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Runner Map Annotation
struct RunnerMapAnnotation: View {
    let runner: RunnerLocation
    
    var body: some View {
        VStack(spacing: 4) {
            // Cercle avec distance
            ZStack {
                Circle()
                    .fill(Color("DarkNavy").opacity(0.9))
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Text("2.8") // TODO: Calculer distance réelle
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("km")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            
            // Flèche pointant vers le bas
            Triangle()
                .fill(Color("DarkNavy").opacity(0.9))
                .frame(width: 12, height: 8)
                .offset(y: -4)
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
