//
//  ProfileView.swift
//  RunningMan
//
//  Created by ChatGPT on the 3/01/2026.
//

import SwiftUI

/// Vue du profil utilisateur avec statistiques et paramètres
struct ProfileView: View {
    
    @Environment(AuthViewModel.self) private var authVM
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header avec avatar
                        profileHeaderSection
                        
                        // Statistiques
                        statsSection
                        
                        // Boutons d'action
                        actionsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.coralAccent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
            
            // Nom et email
            VStack(spacing: 4) {
                Text(authVM.currentUser?.displayName ?? "Utilisateur")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(authVM.currentUser?.email ?? "email@example.com")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Badge
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundColor(.coralAccent)
                Text("Coureur")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.coralAccent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.coralAccent.opacity(0.2))
            .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header inline (remplace un éventuel SessionStepHeader)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.coralAccent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.bar.fill")
                        .font(.headline)
                        .foregroundColor(.coralAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Statistiques")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Vos performances récentes")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Ligne 1 de cartes inline (remplace StatCard)
            HStack(spacing: 12) {
                InlineStatCard(
                    icon: "figure.run",
                    value: "24",
                    unit: nil,
                    label: "Courses",
                    color: .coralAccent
                )
                
                InlineStatCard(
                    icon: "map",
                    value: "125",
                    unit: "km",
                    label: "Distance",
                    color: .blueAccent
                )
                
                InlineStatCard(
                    icon: "timer",
                    value: "18h",
                    unit: nil,
                    label: "Durée",
                    color: .purpleAccent
                )
            }
            
            // Ligne 2 de cartes inline (remplace StatCard)
            HStack(spacing: 12) {
                InlineStatCard(
                    icon: "person.3.fill",
                    value: "3",
                    unit: nil,
                    label: "Squads",
                    color: .greenAccent
                )
                
                InlineStatCard(
                    icon: "flame.fill",
                    value: "2.1k",
                    unit: nil,
                    label: "Calories",
                    color: .yellowAccent
                )
                
                InlineStatCard(
                    icon: "speedometer",
                    value: "5:30",
                    unit: nil,
                    label: "Rythme moy.",
                    color: .pinkAccent
                )
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Modifier le profil
            Button {
                // Action à implémenter
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Modifier le profil")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Historique des courses
            Button {
                // Action à implémenter
            } label: {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Historique des courses")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Déconnexion
            Button {
                authVM.signOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Se déconnecter")
                    Spacer()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Inline Stat Card (remplace StatCard)

private struct InlineStatCard: View {
    let icon: String
    let value: String
    let unit: String?
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let unit = unit, !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
