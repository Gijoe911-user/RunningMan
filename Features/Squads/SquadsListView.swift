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
            HStack {
                Text("Vos squads")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if squadVM.isLoading {
                    ProgressView()
                        .tint(.coralAccent)
                        .scaleEffect(0.8)
                }
            }
            
            // Affichage conditionnel selon l'état
            if squadVM.userSquads.isEmpty {
                // État vide
                emptyStateView
            } else {
                // Liste des squads réels
                VStack(spacing: 12) {
                    ForEach(squadVM.userSquads) { squad in
                        SquadCard(squad: squad)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Aucun squad")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Créez ou rejoignez un squad pour commencer")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Squad Card

struct SquadCard: View {
    @Environment(SquadViewModel.self) private var squadVM
    let squad: SquadModel
    
    var isSelected: Bool {
        squadVM.selectedSquad?.id == squad.id
    }
    
    var memberCount: Int {
        squad.members.count
    }
    
    var adminCount: Int {
        squad.members.filter { $0.value == .admin }.count
    }
    
    var coachCount: Int {
        squad.members.filter { $0.value == .coach }.count
    }
    
    var body: some View {
        NavigationLink {
            SquadDetailView(squad: squad)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Icône du squad avec indicateur de sélection
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isSelected
                                        ? [Color.greenAccent, Color.blueAccent]
                                        : [Color.coralAccent, Color.pinkAccent],
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
                        
                        if isSelected {
                            Circle()
                                .fill(Color.greenAccent)
                                .frame(width: 20, height: 20)
                                .overlay {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                }
                                .offset(x: 5, y: -5)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(squad.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(squad.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Stats et actions
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.3.fill")
                            .font(.caption)
                            .foregroundColor(.coralAccent)
                        Text("\(memberCount)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                        Text("membres")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if adminCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellowAccent)
                            Text("\(adminCount)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Bouton de sélection
                    Button {
                        squadVM.selectSquad(squad)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                            Text(isSelected ? "Actif" : "Activer")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(isSelected ? .greenAccent : .white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.greenAccent, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Squad Card Placeholder (Deprecated - kept for reference)

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
