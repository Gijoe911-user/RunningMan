//
//  ProfileView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
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
            Text("Statistiques")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "figure.run",
                    value: "24",
                    label: "Courses",
                    color: .coralAccent
                )
                
                StatCard(
                    icon: "map",
                    value: "125",
                    unit: "km",
                    label: "Distance",
                    color: .blueAccent
                )
                
                StatCard(
                    icon: "timer",
                    value: "18h",
                    label: "Durée",
                    color: .purpleAccent
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "person.3.fill",
                    value: "3",
                    label: "Squads",
                    color: .greenAccent
                )
                
                StatCard(
                    icon: "flame.fill",
                    value: "2.1k",
                    label: "Calories",
                    color: .yellowAccent
                )
                
                StatCard(
                    icon: "speedometer",
                    value: "5:30",
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

// MARK: - Stat Card (Profil)

struct StatCard: View {
    let icon: String
    let value: String
    var unit: String = ""
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if !unit.isEmpty {
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
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Settings Placeholder (si absent)

//struct SettingsView: View {
//    var body: some View {
//        NavigationStack {
//            Text("Settings")
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(Color.darkNavy.ignoresSafeArea())
//                .navigationTitle("Paramètres")
//        }
//    }
//}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
