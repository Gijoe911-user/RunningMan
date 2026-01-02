//
//  SessionUIComponents.swift
//  RunningMan
//
//  Composants UI réutilisables pour les vues de session
//  Principe DRY : Définis une seule fois, utilisés partout
//

import SwiftUI

// MARK: - Stat Cards

/// Card pour afficher une statistique principale
struct SessionStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Ligne de statistique secondaire
struct SessionSecondaryStatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Item de statistique pour les grilles (version flexible)
struct SessionStatItem: View {
    let icon: String
    let label: String?
    let value: String
    let unit: String?
    let color: Color?
    
    // Initializer pour l'ancien format (icon, label, value)
    init(icon: String, label: String, value: String) {
        self.icon = icon
        self.label = label
        self.value = value
        self.unit = nil
        self.color = nil
    }
    
    // Initializer pour le nouveau format (icon, value, unit, color)
    init(icon: String, value: String, unit: String, color: Color) {
        self.icon = icon
        self.label = nil
        self.value = value
        self.unit = unit
        self.color = color
    }
    
    var body: some View {
        if let color = color, let unit = unit {
            // Style moderne (avec couleur et unité)
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white)
                
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        } else {
            // Style historique (avec label)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                    if let label = label {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Info Cards

/// Card d'information générique
struct SessionInfoCard: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(items, id: \.0) { key, value in
                    HStack {
                        Text(key)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    if key != items.last?.0 {
                        Divider()
                            .background(.white.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Card pour les notes
struct SessionNotesCard: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.white.opacity(0.7))
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(notes)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Participants

/// Ligne de podium
struct SessionPodiumRow: View {
    let rank: Int
    let participantStat: ParticipantStats
    let userName: String
    
    private var medalIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Médaille/Rang
            Text(medalIcon)
                .font(.title2)
                .frame(width: 40)
            
            // Nom
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(String(format: "%.2f km", participantStat.distance / 1000))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(participantStat.duration))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.coralAccent)
                
                Text(String(format: "%.1f km/h", participantStat.averageSpeed * 3.6))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            rank <= 3
                ? Color.white.opacity(0.1)
                : Color.white.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let totalMinutes = (Int(seconds) % 3600) / 60
        let remainingSeconds = Int(seconds) - (hours * 3600) - (totalMinutes * 60)
        
        if hours > 0 {
            return String(format: "%dh%02d", hours, totalMinutes)
        } else {
            return String(format: "%d:%02d", totalMinutes, remainingSeconds)
        }
    }
}

/// Card détaillée d'un participant
struct SessionParticipantDetailCard: View {
    let participantStat: ParticipantStats
    let userName: String
    let participantState: ParticipantSessionState?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête avec nom et statut
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let state = participantState {
                        HStack(spacing: 4) {
                            Image(systemName: state.status.icon)
                                .font(.caption)
                            Text(state.status.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(colorForStatus(state.status.colorName))
                    }
                }
                
                Spacer()
                
                // Statut emoji
                if let state = participantState {
                    Text(state.status.emoji)
                        .font(.title)
                }
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SessionStatItem(icon: "figure.run", label: "Distance", value: String(format: "%.2f km", participantStat.distance / 1000))
                SessionStatItem(icon: "clock.fill", label: "Durée", value: formatDuration(participantStat.duration))
                SessionStatItem(icon: "speedometer", label: "Vitesse moy.", value: String(format: "%.1f km/h", participantStat.averageSpeed * 3.6))
                SessionStatItem(icon: "gauge.high", label: "Vitesse max", value: String(format: "%.1f km/h", participantStat.maxSpeed * 3.6))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh%02d", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
    
    private func colorForStatus(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Map

/// Item de statistique pour la carte
struct SessionMapStatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.coralAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Empty States

/// Vue d'état vide réutilisable
struct SessionEmptyStateView: View {
    let icon: String
    let message: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Headers

/// En-tête pour les étapes de création
struct SessionStepHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.coralAccent, .pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.coralAccent)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
struct RunnerCompactCard: View {
    let runner: RunnerLocation
    
    var body: some View {
        VStack(spacing: 4) {
            // Avatar
            if let photoURL = runner.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.coralAccent.opacity(0.3))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(.coralAccent)
                        }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.coralAccent.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.coralAccent)
                    }
            }
            
            // Nom
            Text(runner.displayName)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 60)
    }
}

