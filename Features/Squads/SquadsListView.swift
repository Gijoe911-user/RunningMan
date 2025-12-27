//
//  SquadsListView.swift
//  RunningMan
//
//  Liste des Squads de l'utilisateur
//

import SwiftUI

struct SquadsListView: View {
    @StateObject private var viewModel = SquadsViewModel()
    @State private var showCreateSquad = false
    @State private var showJoinSquad = false
    
    var body: some View {
        ZStack {
            // Fond
            Color.darkNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Mes Squads")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Menu {
                            Button {
                                showCreateSquad = true
                            } label: {
                                Label("Créer une Squad", systemImage: "plus.circle")
                            }
                            
                            Button {
                                showJoinSquad = true
                            } label: {
                                Label("Rejoindre une Squad", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title2)
                                .foregroundColor(.coralAccent)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Liste des squads
                    if viewModel.squads.isEmpty {
                        EmptySquadsView(
                            onCreateSquad: { showCreateSquad = true },
                            onJoinSquad: { showJoinSquad = true }
                        )
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.squads) { squad in
                                NavigationLink(destination: SquadDetailView(squad: squad)) {
                                    SquadCard(squad: squad)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showCreateSquad) {
            CreateSquadView()
        }
        .sheet(isPresented: $showJoinSquad) {
            JoinSquadView()
        }
        .onAppear {
            viewModel.loadSquads()
        }
    }
}

// MARK: - Squad Card
struct SquadCard: View {
    let squad: SquadModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icône squad
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.coralAccent)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(squad.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(squad.memberCount) membres")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Indication sessions actives
            if squad.hasActiveSessions {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("Session en cours")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Empty Squads View
struct EmptySquadsView: View {
    let onCreateSquad: () -> Void
    let onJoinSquad: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 80))
                .foregroundColor(.coralAccent.opacity(0.5))
            
            Text("Aucune Squad")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Créez ou rejoignez une Squad pour commencer à courir ensemble !")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    onCreateSquad()
                } label: {
                    Label("Créer une Squad", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.coralAccent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    onJoinSquad()
                } label: {
                    Label("Rejoindre avec un code", systemImage: "key.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}
