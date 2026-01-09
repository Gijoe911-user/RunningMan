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
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            Logger.log("[MAP-SIMPLE] ✅ onAppear - runners: \(runnerLocations.count), routePts: \(routePoints.count), userLoc: \(userLocation.map { "\($0.latitude), \($0.longitude)" } ?? "nil")", category: .ui)
            Logger.log("[MAP-SIMPLE] 🎥 initial mapPosition: \(describePosition(mapPosition))", category: .ui)
            
            // 🆕 Vérifier l'autorisation de localisation
            #if DEBUG
            let locationProvider = LocationProvider.shared
            Logger.log("[MAP-SIMPLE] 🔐 Location auth status: \(locationProvider.authorizationStatus.rawValue)", category: .ui)
            Logger.log("[MAP-SIMPLE] 📡 Location isUpdating: \(locationProvider.isUpdating)", category: .ui)
            Logger.log("[MAP-SIMPLE] 📍 Current coordinate: \(locationProvider.currentCoordinate.map { "\($0.latitude), \($0.longitude)" } ?? "nil")", category: .ui)
            #endif
        }
        .onDisappear {
            Logger.log("[MAP-SIMPLE] 👋 onDisappear", category: .ui)
        }
        .onChange(of: equatableLocation) { 
            Logger.log("[MAP-SIMPLE] 📍 equatableLocation changed to \(equatableLocation.map { "\($0.latitude), \($0.longitude)" } ?? "nil")", category: .ui)
            // Ne centrer automatiquement que si aucune position spécifique n'est définie
            guard let newLocation = equatableLocation else { return }
            
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
                Logger.log("[MAP-SIMPLE] 🎯 recenter to user (automatic) @ \(newLocation.latitude), \(newLocation.longitude)", category: .ui)
            }
        }
        .onChange(of: runnerLocations.count) { 
            Logger.log("[MAP-SIMPLE] 👥 runnerLocations count changed to \(runnerLocations.count)", category: .ui)
        }
        .onChange(of: routePoints.count) { 
            Logger.log("[MAP-SIMPLE] 🧵 routePoints count changed to \(routePoints.count)", category: .ui)
        }
        .onChange(of: mapPosition) { 
            Logger.log("[MAP-SIMPLE] 🎥 mapPosition changed to \(describePosition(mapPosition))", category: .ui)
        }
    }
    
    private func describePosition(_ pos: MapCameraPosition) -> String {
        if pos.followsUserLocation {
            return "userLocation"
        }
        
        if let camera = pos.camera {
            let lat = camera.centerCoordinate.latitude
            let lon = camera.centerCoordinate.longitude
            let dist = camera.distance
            return "camera(center: \(lat), \(lon), dist: \(dist))"
        }
        
        if let region = pos.region {
            let lat = region.center.latitude
            let lon = region.center.longitude
            return "region(center: \(lat), \(lon))"
        }
        
        if pos == .automatic {
            return "automatic"
        }
        
        return "other/unknown"
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
        .onAppear {
            Logger.log("[MAP-SIMPLE] 🏷️ Runner annotation appear: \(runner.id) @ \(runner.latitude), \(runner.longitude)", category: .ui)
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

