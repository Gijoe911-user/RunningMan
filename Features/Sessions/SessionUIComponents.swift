//
//  SessionUIComponents.swift
//  RunningMan
//
//  Composants UI réutilisables pour les sessions
//

import SwiftUI

// MARK: - Stat Badge

/// Badge pour afficher une statistique rapide
///
/// Composant simple avec icône, valeur et label.
///
/// **Usage :**
/// ```swift
/// StatBadge(
///     icon: "figure.run",
///     value: "5",
///     label: "Coureurs"
/// )
/// ```
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

// MARK: - Runner Compact Card

/// Carte compacte pour afficher un coureur
///
/// Affiche :
/// - Avatar du coureur (photo ou placeholder)
/// - Nom en dessous
///
/// **Usage :**
/// ```swift
/// RunnerCompactCard(runner: runnerLocation)
/// ```
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

// MARK: - Runner Row View

/// Vue en ligne pour afficher un coureur
///
/// Affiche :
/// - Avatar
/// - Nom
/// - Timestamp
///
/// **Usage :**
/// ```swift
/// RunnerRowView(runner: runnerLocation)
/// ```
struct RunnerRowView: View {
    let runner: RunnerLocation
    
    var body: some View {
        HStack {
            // Avatar
            if let photoURL = runner.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            
            // Info
            VStack(alignment: .leading) {
                Text(runner.displayName)
                    .font(.headline)
                Text(runner.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("StatBadge") {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        HStack(spacing: 20) {
            StatBadge(icon: "figure.run", value: "5", label: "Coureurs")
            StatBadge(icon: "clock.fill", value: "20:45", label: "Temps")
            StatBadge(icon: "location.fill", value: "5.0 km", label: "Objectif")
        }
        .padding()
    }
}
