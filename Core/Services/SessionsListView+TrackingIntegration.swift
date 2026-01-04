//
//  SessionsListView+TrackingIntegration.swift
//  RunningMan
//
//  Exemple d'intégration des contrôles de tracking GPS dans SessionsListView
//

import SwiftUI

/*
 
 GUIDE D'INTÉGRATION DU TRACKING GPS
 ====================================
 
 1. AJOUTER LE VIEWMODEL
 ------------------------
 
 Dans SessionsListView, ajouter :
 
 ```swift
 @StateObject private var trackingVM: SessionTrackingViewModel?
 
 // Dans onAppear ou task:
 if let session = viewModel.activeSession,
    let sessionId = session.id,
    let userId = AuthService.shared.currentUserId {
     trackingVM = SessionTrackingViewModel(sessionId: sessionId, userId: userId)
 }
 ```
 
 2. AFFICHER LE BADGE DE STATUT
 --------------------------------
 
 En haut de la carte (ZStack avec alignment: .top) :
 
 ```swift
 if let trackingVM = trackingVM {
     VStack {
         TrackingStatusIndicator(
             trackingState: trackingVM.trackingState,
             duration: trackingVM.trackingDuration
         )
         .padding(.top, 60) // Sous la safe area
         .padding(.horizontal)
         
         Spacer()
     }
 }
 ```
 
 3. AFFICHER LES CONTRÔLES
 --------------------------
 
 Au-dessus du SessionActiveOverlay :
 
 ```swift
 if let trackingVM = trackingVM {
     SessionTrackingControls(
         trackingState: $trackingVM.trackingState,
         onStart: {
             trackingVM.startTracking()
         },
         onPause: {
             trackingVM.pauseTracking()
         },
         onResume: {
             trackingVM.resumeTracking()
         },
         onStop: {
             Task {
                 await trackingVM.stopTracking()
                 // Optionnel : fermer la session, revenir à l'écran précédent, etc.
             }
         }
     )
     .padding(.horizontal)
     .padding(.bottom, 8)
 }
 ```
 
 4. METTRE À JOUR LA CARTE
 --------------------------
 
 Utiliser les points enregistrés dans la carte :
 
 ```swift
 EnhancedSessionMapView(
     userLocation: viewModel.userLocation,
     runnerLocations: viewModel.activeRunners,
     routeCoordinates: trackingVM?.recordedPoints ?? [], // ✅ Points du tracking
     runnerRoutes: [:],
     onRecenter: { ... },
     onSaveRoute: { ... }
 )
 ```
 
 5. AFFICHER LES STATS EN TEMPS RÉEL
 ------------------------------------
 
 Mettre à jour le widget de stats :
 
 ```swift
 SessionStatsWidget(
     session: session,
     currentHeartRate: viewModel.currentHeartRate,
     currentCalories: viewModel.currentCalories,
     routeDistance: trackingVM?.currentDistance ?? 0 // ✅ Distance du tracking
 )
 ```
 
 ARCHITECTURE COMPLÈTE
 =====================
 
 SessionsListView
 ├── @StateObject var viewModel: SessionsViewModel (géolocalisation)
 ├── @StateObject var trackingVM: SessionTrackingViewModel? (tracking GPS)
 │
 └── ZStack {
         // Carte
         EnhancedSessionMapView(routeCoordinates: trackingVM.recordedPoints)
         
         // Badge de statut (top)
         TrackingStatusIndicator(trackingState, duration)
         
         // Stats widget (center-top)
         SessionStatsWidget(distance: trackingVM.currentDistance)
         
         // Contrôles de tracking (bottom)
         SessionTrackingControls(...)
         
         // Overlay de session (bottom)
         SessionActiveOverlay(...)
     }
 
 NOTIFICATIONS & OBSERVERS
 ==========================
 
 Le SessionTrackingViewModel écoute automatiquement les mises à jour de position
 via NotificationCenter (.locationDidUpdate).
 
 Pour déclencher ces notifications, dans RealtimeLocationService :
 
 ```swift
 func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     guard let location = locations.last else { return }
     
     // ... code existant ...
     
     // Publier la notification
     NotificationCenter.default.post(
         name: .locationDidUpdate,
         object: location
     )
 }
 ```
 
 */

// Ce fichier est un guide uniquement, pas de code à exécuter.
