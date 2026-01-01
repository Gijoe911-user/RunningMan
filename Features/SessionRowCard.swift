//
//  SessionRowCard.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 31/12/2025.
//
// ✅ Ce composant est stratégique car il gère 3 états différents pour l'utilisateur :
//   - C'est ma propre session (déjà en cours de tracking) → Badge "LIVE" vert
//   - C'est une session que je peux rejoindre pour courir (Runner) → Menu "Démarrer mon tracking"
//   - C'est une session que je veux simplement regarder (Supporter) → Menu "Suivre la session"
//
// ✅ INTÉGRATION : Ce composant est maintenant intégré dans AllSessionsViewUnified.swift
//
// Exemple d'utilisation :
// ForEach(viewModel.allActiveSessions) { session in
//     SessionRowCard(
//         session: session,
//         isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
//         onJoin: {
//             Task {
//                 if let sessionId = session.id {
//                     _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
//                 }
//             }
//         },
//         onStartTracking: {
//             Task {
//                 _ = await viewModel.startTracking(for: session)
//             }
//         }
//     )
// }
//
// Pour plus d'exemples, voir : EXEMPLE_UTILISATION_SESSIONROWCARD.swift

import SwiftUI

struct SessionRowCard: View {
    let session: SessionModel
    let isMyTracking: Bool
    let onJoin: () -> Void
    let onStartTracking: () -> Void
    
    @State private var showActions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 1. Icône dynamique selon l'activité
            ZStack {
                Circle()
                    .fill(isMyTracking ? Color.coralAccent.opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 45, height: 45)
                
                Image(systemName: session.activityType.icon)
                    .font(.title3)
                    .foregroundColor(isMyTracking ? .coralAccent : .white)
            }
            
            // 2. Informations de la session
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.activityType.displayName)
                        .font(.caption.bold())
                        .foregroundColor(isMyTracking ? .coralAccent : .white.opacity(0.6))
                    
                    // Badge visuel pour les courses compétitives
                    if session.activityType == .race {
                        Text("COURSE")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                Text("\(session.participants.count) coureurs en live")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                // Stats rapides (Distance et Temps écoulé)
                HStack(spacing: 8) {
                    Label(String(format: "%.2f km", session.distanceInKilometers), systemImage: "figure.run")
                    Text("•")
                    Label(session.formattedDuration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // 3. Actions contextuelles
            if isMyTracking {
                // Indicateur de statut "En cours"
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
            } else {
                // Bouton d'action pour les sessions des autres
                Button {
                    showActions = true
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundColor(.coralAccent)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isMyTracking ? Color.coralAccent.opacity(0.05) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isMyTracking ? Color.coralAccent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        // Menu de choix d'action
        .confirmationDialog("Options de session", isPresented: $showActions, titleVisibility: .visible) {
            Button("Démarrer mon tracking (Runner)") {
                onStartTracking()
            }
            
            Button("Suivre la session (Supporter)") {
                onJoin()
            }
            
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Voulez-vous rejoindre cette session pour courir ou simplement encourager la squad ?")
        }
    }
}
