//
//  DashboardView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue principale du dashboard
struct DashboardView: View {
    
    @Environment(AuthViewModel.self) private var authVM
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        if let user = authVM.currentUser {
                            VStack(spacing: 8) {
                                Text("Bonjour, \(user.displayName)! 👋")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                Text("Prêt pour votre prochaine course ?")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                        
                        // Quick Stats
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Cette semaine")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                DashboardStatCard(
                                    icon: "figure.run",
                                    value: "5",
                                    label: "Courses",
                                    color: .coralAccent
                                )
                                
                                DashboardStatCard(
                                    icon: "map",
                                    value: "24 km",
                                    label: "Distance",
                                    color: .blueAccent
                                )
                                
                                DashboardStatCard(
                                    icon: "clock",
                                    value: "3h 12m",
                                    label: "Temps",
                                    color: .purpleAccent
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Activité récente")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                Text("Aucune activité récente")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Squads Section
                        if !squadVM.userSquads.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Mes Squads")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    NavigationLink {
                                        SquadListView()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("Voir tout")
                                                .font(.subheadline)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.coralAccent)
                                    }
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(squadVM.userSquads.prefix(3)) { squad in
                                            DashboardSquadCard(squad: squad)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Accueil")
        }
    }
}

// MARK: - Dashboard Stat Card

struct DashboardStatCard: View {
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
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Dashboard Squad Card

struct DashboardSquadCard: View {
    let squad: SquadModel
    
    var memberCount: Int {
        squad.members.count
    }
    
    var body: some View {
        NavigationLink {
            SquadDetailView(squad: squad)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Icône
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
                        Image(systemName: "person.3.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(squad.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.caption2)
                        Text("\(memberCount) membres")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 140)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(AuthViewModel())
        .environment(SquadViewModel())
        .preferredColorScheme(.dark)
}
