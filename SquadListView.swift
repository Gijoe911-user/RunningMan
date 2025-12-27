//
//  SquadListView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue de liste de tous les squads de l'utilisateur
struct SquadListView: View {
    
    @Environment(SquadViewModel.self) private var squadVM
    @State private var showCreateSquad = false
    @State private var showJoinSquad = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Boutons d'action en haut
                        actionButtonsSection
                        
                        // Liste des squads
                        squadsListSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Mes Squads")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await squadVM.loadUserSquads()
            }
            .sheet(isPresented: $showCreateSquad) {
                CreateSquadView()
            }
            .sheet(isPresented: $showJoinSquad) {
                JoinSquadView()
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Bouton Créer
            Button {
                showCreateSquad = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Créer")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Bouton Rejoindre
            Button {
                showJoinSquad = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Rejoindre")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blueAccent, Color.purpleAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    // MARK: - Squads List
    
    private var squadsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vos squads")
                .font(.headline)
                .foregroundColor(.white)
            
            // Liste temporaire - sera remplacée par les vrais squads
            VStack(spacing: 12) {
                SquadCardPlaceholder(
                    name: "Marathon 2024",
                    description: "Préparation marathon de Paris",
                    members: 5,
                    supporters: 2
                )
                
                SquadCardPlaceholder(
                    name: "Les Runners du Dimanche",
                    description: "Course tranquille le dimanche matin",
                    members: 3,
                    supporters: 1
                )
                
                SquadCardPlaceholder(
                    name: "Team Sprint",
                    description: "Entraînement fractionné hebdomadaire",
                    members: 4,
                    supporters: 3
                )
            }
        }
    }
}

// MARK: - Squad Card Placeholder

struct SquadCardPlaceholder: View {
    let name: String
    let description: String
    let members: Int
    let supporters: Int
    
    // Créer un mock SquadModel pour la navigation
    private var mockSquad: SquadModel {
        SquadModel(
            name: name,
            description: description,
            inviteCode: "MOCK00",
            creatorId: "mockUser",
            members: ["mockUser": .admin]
        )
    }
    
    var body: some View {
        NavigationLink {
            SquadDetailView(squad: mockSquad)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Icône du squad
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.coralAccent, Color.pinkAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "person.3.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Stats
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.caption)
                            .foregroundColor(.coralAccent)
                        Text("\(members) coureurs")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.caption)
                            .foregroundColor(.blueAccent)
                        Text("\(supporters) supporters")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SquadListView()
        .preferredColorScheme(.dark)
}
