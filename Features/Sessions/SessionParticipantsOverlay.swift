//
//  SessionParticipantsOverlay.swift
//  RunningMan
//
//  Overlay affichant les participants avec interaction pour centrer la carte
//

import SwiftUI
import CoreLocation

struct SessionParticipantsOverlay: View {
    let participants: [RunnerLocation]
    let userLocation: CLLocationCoordinate2D?
    let onRunnerTap: (String) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            // Liste des participants (si étendu)
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Vous (l'utilisateur actuel)
                        if userLocation != nil {
                            currentUserCard
                        }
                        
                        // Autres participants
                        ForEach(participants) { runner in
                            RunnerCard(
                                runner: runner,
                                onTap: {
                                    onRunnerTap(runner.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxHeight: 140)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.headline)
                    .foregroundColor(.coralAccent)
                
                Text("Participants")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("(\(totalParticipants))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Bouton expand/collapse
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var totalParticipants: Int {
        participants.count + (userLocation != nil ? 1 : 0)
    }
    
    // MARK: - Current User Card
    
    private var currentUserCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.coralAccent, Color.pinkAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vous")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("En course")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 160)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.coralAccent.opacity(0.5), Color.pinkAccent.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Runner Card

struct RunnerCard: View {
    let runner: RunnerLocation
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay {
                            if let photoURL = runner.photoURL, let url = URL(string: photoURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(runner.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            
                            Text("En course")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(12)
            }
            .frame(width: 160)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            SessionParticipantsOverlay(
                participants: [
                    RunnerLocation(
                        id: "user1",
                        displayName: "Jean Martin",
                        latitude: 48.8576,
                        longitude: 2.3532,
                        timestamp: Date(),
                        photoURL: nil
                    ),
                    RunnerLocation(
                        id: "user2",
                        displayName: "Marie Dubois",
                        latitude: 48.8556,
                        longitude: 2.3512,
                        timestamp: Date(),
                        photoURL: nil
                    ),
                    RunnerLocation(
                        id: "user3",
                        displayName: "Pierre Durant",
                        latitude: 48.8546,
                        longitude: 2.3502,
                        timestamp: Date(),
                        photoURL: nil
                    )
                ],
                userLocation: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
                onRunnerTap: { id in
                    print("Tapped runner: \(id)")
                }
            )
            .padding(Edge.Set.bottom, 100)
        }
    }
    .preferredColorScheme(.dark)
}
