//
//  HomeWelcomeView.swift
//  RunningMan
//
//  Vue d'accueil post-authentification avec onboarding
//

import SwiftUI

struct HomeWelcomeView: View {
    
    @Environment(SquadViewModel.self) private var squadsVM
    @State private var showOnboarding = false
    @State private var hasSeenOnboarding = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                if squadsVM.userSquads.isEmpty {
                    // Nouvel utilisateur sans squad
                    newUserView
                } else {
                    // Utilisateur avec au moins une squad
                    dashboardView
                }
            }
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showOnboarding = true
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.coralAccent)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView {
                    hasSeenOnboarding = true
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
            }
            .onAppear {
                checkFirstLaunch()
            }
        }
    }
    
    // MARK: - New User View
    
    private var newUserView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero section
                VStack(spacing: 20) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.coralAccent)
                        .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        Text("Bienvenue sur RunningMan")
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Courez ensemble, où que vous soyez")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
                
                // Help button
                Button {
                    showOnboarding = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Comment ça marche ?")
                                .font(.headline)
                            
                            Text("Découvrez les Squads, Sessions et Notifications")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.coralAccent, .pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .coralAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                
                // Quick start cards
                quickStartCards
                
                Spacer()
            }
        }
    }
    
    // MARK: - Dashboard View
    
    private var dashboardView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bonjour !")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text("Prêt pour votre prochaine course ?")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Help card
                helpCard
                
                // Quick actions
                quickActions
                
                // Stats summary (if available)
                // TODO: Add recent stats
                
                Spacer()
            }
        }
    }
    
    // MARK: - Quick Start Cards
    
    private var quickStartCards: some View {
        VStack(spacing: 16) {
            Text("Pour commencer")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                QuickStartCard(
                    icon: "person.3.fill",
                    title: "Créez votre première Squad",
                    description: "Invitez vos amis coureurs",
                    color: .coralAccent,
                    action: {
                        // Navigate to create squad
                    }
                )
                
                QuickStartCard(
                    icon: "calendar.badge.plus",
                    title: "Planifiez une session",
                    description: "Organisez votre première course",
                    color: .pinkAccent,
                    action: {
                        // Navigate to create session
                    }
                )
                
                QuickStartCard(
                    icon: "map.fill",
                    title: "Explorez les fonctionnalités",
                    description: "Découvrez le tracking GPS et les notifications",
                    color: .blueAccent,
                    action: {
                        showOnboarding = true
                    }
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Help Card
    
    private var helpCard: some View {
        Button {
            showOnboarding = true
        } label: {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.coralAccent.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundColor(.coralAccent)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Besoin d'aide ?")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.coralAccent)
                    }
                    
                    Text("Appuyez pour découvrir les fonctionnalités avec audio")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions rapides")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                QuickActionButton(
                    icon: "figure.run",
                    title: "Sessions",
                    color: .coralAccent
                ) {
                    // Navigate to sessions
                }
                
                QuickActionButton(
                    icon: "bell.fill",
                    title: "Notifications",
                    color: .pinkAccent
                ) {
                    // Navigate to notifications
                }
                
                QuickActionButton(
                    icon: "person.3.fill",
                    title: "Squads",
                    color: .blueAccent
                ) {
                    // Navigate to squads
                }
                
                QuickActionButton(
                    icon: "person.fill",
                    title: "Profil",
                    color: Color.green
                ) {
                    // Navigate to profile
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helpers
    
    private func checkFirstLaunch() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        if !hasSeenOnboarding {
            // Afficher l'onboarding après un court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showOnboarding = true
            }
        }
    }
}

// MARK: - Quick Start Card

struct QuickStartCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: icon)
                            .foregroundColor(color)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(color)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    }
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview

#Preview {
    HomeWelcomeView()
        .environment(SquadViewModel())
}
