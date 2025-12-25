//
//  OnboardingSquadView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue d'onboarding pour les nouveaux utilisateurs sans squad
struct OnboardingSquadView: View {
    
    @Environment(AuthViewModel.self) private var authVM
    @State private var showCreateSquad = false
    @State private var showJoinSquad = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.darkNavy, Color.purpleAccent.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Icône et titre
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.coralAccent)
                            .symbolEffect(.bounce)
                        
                        VStack(spacing: 8) {
                            Text("Bienvenue sur RunningMan !")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Rejoignez ou créez votre premier squad pour commencer")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                    
                    // Boutons d'action
                    VStack(spacing: 16) {
                        // Bouton Créer un Squad
                        Button {
                            showCreateSquad = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Créer un Squad")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.coralAccent, Color.pinkAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Bouton Rejoindre un Squad
                        Button {
                            showJoinSquad = true
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2)
                                Text("Rejoindre un Squad")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.blueAccent, Color.purpleAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authVM.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showCreateSquad) {
                CreateSquadView()
            }
            .sheet(isPresented: $showJoinSquad) {
                JoinSquadView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingSquadView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
