//
//  SessionCardComponents.swift
//  RunningMan
//
//  Composants de cartes réutilisables pour les sessions
//  ✅ DRY : Don't Repeat Yourself - Tous les composants de cartes sont ici
//

import SwiftUI

// MARK: - Tracking Session Card (Ma session active avec GPS)

struct TrackingSessionCard: View {
    let session: SessionModel
    let distance: Double
    let duration: TimeInterval
    let state: TrackingState
    
    var body: some View {
        VStack(spacing: 16) {
            // En-tête
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.activityType.displayName.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(Color.coralAccent)
                    
                    Text("Session en cours")
                        .font(.title3.bold())
                        .foregroundColor(Color.white)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                    
                    Text(state.displayName)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.8))
                }
            }
            
            // Stats en temps réel
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DISTANCE")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text(FormatHelper.formattedDistance(distance))
                        .font(.title2.bold())
                        .foregroundColor(Color.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("DURÉE")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text(FormatHelper.formattedDuration(duration))
                        .font(.title2.bold())
                        .foregroundColor(Color.white)
                }
            }
            
            // Indicateur de navigation
            HStack {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(Color.coralAccent)
                
                Text("Voir les détails")
                    .font(.subheadline)
                    .foregroundColor(Color.coralAccent)
                
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.coralAccent.opacity(0.2), Color.pinkAccent.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
    
    private var stateColor: Color {
        switch state {
        case .idle: return Color.gray
        case .active: return Color.green
        case .paused: return Color.orange
        case .stopping: return Color.red
        }
    }
}

// MARK: - Supporter Session Card (Sessions que je suis)

struct SupporterSessionCard: View {
    let session: SessionModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 45, height: 45)
                
                Image(systemName: "eyes.inverse")
                    .font(.title3)
                    .foregroundColor(Color.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.activityType.displayName)
                    .font(.caption.bold())
                    .foregroundColor(Color.blue)
                
                Text("\(session.participants.count) coureurs en live")
                    .font(.subheadline.bold())
                    .foregroundColor(Color.white)
                
                HStack(spacing: 8) {
                    Label(session.formattedDistance, systemImage: "figure.run")
                    Text("•")
                    Label(session.formattedSessionDuration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - History Session Card (Sessions terminées)

struct HistorySessionCard: View {
    let session: SessionModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 45, height: 45)
                
                Image(systemName: session.activityType.icon)
                    .font(.title3)
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.activityType.displayName)
                    .font(.caption.bold())
                    .foregroundColor(Color.white.opacity(0.5))
                
                if let endedAt = session.endedAt {
                    Text(endedAt.formattedDateTime)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.white)
                }
                
                HStack(spacing: 8) {
                    Label(session.formattedDistance, systemImage: "figure.run")
                    Text("•")
                    Label(session.formattedSessionDuration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stat Badge Compact (Badge de statistique compact)

struct StatBadgeCompact: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.coralAccent)
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(Color.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Tracking Card") {
    TrackingSessionCard(
        session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            participants: ["user1"],
            totalDistanceMeters: 5200,
            durationSeconds: 2730
        ),
        distance: 5200,
        duration: 2730,
        state: .active
    )
    .padding()
    .background(Color.darkNavy)
}

#Preview("Supporter Card") {
    SupporterSessionCard(
        session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            participants: ["user1", "user2", "user3"],
            totalDistanceMeters: 2100,
            durationSeconds: 900
        )
    )
    .padding()
    .background(Color.darkNavy)
}

#Preview("History Card") {
    HistorySessionCard(
        session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            endedAt: Date().addingTimeInterval(-86400),
            status: .ended,
            participants: ["user1"],
            totalDistanceMeters: 10200,
            durationSeconds: 3600
        )
    )
    .padding()
    .background(Color.darkNavy)
}
