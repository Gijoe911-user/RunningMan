//
//  TEMPLATE - Vue de tracking de session
//  RunningMan
//
//  🎯 TEMPLATE : Comment utiliser correctement SessionTrackingControlsView
//  
//  ⚠️ Ce fichier est un TEMPLATE, pas une vue fonctionnelle !
//  Copiez ce pattern dans votre vraie vue de tracking.
//

import SwiftUI
import MapKit

/// 🎯 TEMPLATE : Vue complète de tracking d'une session
///
/// **Points clés :**
/// 1. La session DOIT avoir un ID valide (chargée depuis Firestore)
/// 2. On passe l'état `trackingState` depuis `TrackingManager`
/// 3. Les callbacks appellent directement `TrackingManager.shared`
/// 4. L'UI se met à jour automatiquement grâce aux `@Published`
struct TemplateSessionTrackingView: View {
    
    // MARK: - Properties
    
    /// ✅ Session AVEC un ID valide (chargée depuis Firestore)
    let session: SessionModel
    
    /// TrackingManager (singleton)
    @StateObject private var trackingManager = TrackingManager.shared
    
    /// État local pour la navigation
    @State private var showEndConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Carte avec le tracé GPS
            MapView(routeCoordinates: trackingManager.routeCoordinates)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay avec stats + contrôles
            VStack {
                Spacer()
                
                // Stats de la session
                statsCard
                
                // 🎯 CONTRÔLES DE TRACKING
                // ✅ CORRECTION : Utiliser SessionTrackingHelper pour validation automatique de l'ID
                SessionTrackingControlsView(
                    session: session,  // ✅ Session (avec ou sans ID)
                    trackingState: Binding(
                        get: { trackingManager.trackingState },
                        set: { _ in /* Read-only */ }
                    ),
                    onStart: {
                        // ✅ NOUVEAU : Helper qui recharge la session si l'ID est nil
                        let success = await SessionTrackingHelper.startTracking(
                            for: session,
                            using: trackingManager
                        )
                        
                        if !success {
                            print("❌ Échec démarrage tracking")
                        }
                    },
                    onPause: {
                        await trackingManager.pauseTracking()
                    },
                    onResume: {
                        await trackingManager.resumeTracking()
                    },
                    onStop: {
                        // Demander confirmation avant d'arrêter
                        showEndConfirmation = true
                    }
                )
                .padding()
            }
        }
        .navigationTitle("Session en cours")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Terminer la session ?",
            isPresented: $showEndConfirmation,
            titleVisibility: .visible
        ) {
            Button("Terminer", role: .destructive) {
                Task {
                    do {
                        try await trackingManager.stopTracking()
                        dismiss()
                    } catch {
                        print("❌ Erreur arrêt tracking: \(error)")
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action va terminer votre tracking et sauvegarder vos données.")
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // Distance
                StatItem(
                    icon: "figure.run",
                    value: String(format: "%.2f", trackingManager.currentDistance / 1000),
                    unit: "km"
                )
                
                // Durée
                StatItem(
                    icon: "timer",
                    value: formatDuration(trackingManager.currentDuration),
                    unit: ""
                )
                
                // Vitesse
                StatItem(
                    icon: "speedometer",
                    value: String(format: "%.1f", trackingManager.currentSpeed * 3.6),
                    unit: "km/h"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct MapView: View {
    let routeCoordinates: [CLLocationCoordinate2D]
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: []) { _ in
            MapMarker(coordinate: region.center, tint: .blue)
        }
        .onAppear {
            if let firstCoordinate = routeCoordinates.first {
                region.center = firstCoordinate
            }
        }
    }
}

// MARK: - 🎯 EXEMPLE D'UTILISATION

/// ✅ Comment créer une session ET naviguer vers la vue de tracking
///
/// **Pattern recommandé :**
/// 1. Créer la session via `SessionService.shared.createSession()`
/// 2. La session retournée a un ID valide
/// 3. Naviguer vers la vue de tracking avec cette session
///
/// ```swift
/// Button("Créer une session") {
///     Task {
///         do {
///             // 1. Créer la session (retourne une session avec ID)
///             let session = try await SessionService.shared.createSession(
///                 squadId: squad.id,
///                 creatorId: currentUserId
///             )
///             
///             // 2. Vérifier que l'ID existe
///             guard session.id != nil else {
///                 print("❌ Session sans ID")
///                 return
///             }
///             
///             // 3. Naviguer vers la vue de tracking
///             navigateToTrackingView(session: session)
///             
///         } catch {
///             print("❌ Erreur création session: \(error)")
///         }
///     }
/// }
/// ```

// MARK: - 🚨 ANTI-PATTERN (À ÉVITER)

/// ❌ NE PAS FAIRE ÇA :
///
/// ```swift
/// // ❌ MAUVAIS : Créer une session locale sans ID
/// let localSession = SessionModel(
///     squadId: "squad1",
///     creatorId: "user1"
/// )
/// // localSession.id est nil !
///
/// // ❌ MAUVAIS : Passer cette session au TrackingManager
/// await trackingManager.startTracking(for: localSession)
/// // → ERREUR : "Session ID manquant"
/// ```
///
/// **Solution :**
/// Toujours créer la session via `SessionService.shared.createSession()`
/// qui retourne une session avec un ID Firebase valide.

// MARK: - Preview

#Preview {
    NavigationStack {
        TemplateSessionTrackingView(
            session: SessionModel(
                id: "preview-session-id",  // ✅ ID présent
                squadId: "squad1",
                creatorId: "user1",
                startedAt: Date(),
                status: .scheduled,
                participants: ["user1"]
            )
        )
    }
}
