//
//  SquadDetailView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue de détail d'un squad avec feed d'activités
struct SquadDetailView: View {
    let squad: SquadModel
    
    @State private var showLeaveConfirmation = false
    @State private var showStartSession = false
    @State private var isLeaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header du squad
                    squadHeaderSection
                    
                    // Code d'invitation
                    inviteCodeSection
                    
                    // Actions principales
                    actionsSection
                    
                    // Membres
                    membersSection
                    
                    // Statistiques (placeholder)
                    statsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle(squad.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Quitter la squad ?", isPresented: $showLeaveConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Quitter", role: .destructive) {
                leaveSquad()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir quitter \(squad.name) ?")
        }
        .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showStartSession) {
            CreateSessionView(squad: squad)
        }
    }
    
    // MARK: - Actions
    
    private func leaveSquad() {
        guard let userId = AuthService.shared.currentUserId else { return }
        
        isLeaving = true
        
        Task {
            do {
                if let squadId = squad.id {
                    try await SquadService.shared.leaveSquad(squadId: squadId, userId: userId)
                    // TODO: Navigation back
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLeaving = false
        }
    }
    
    // MARK: - Squad Header
    
    private var squadHeaderSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "person.3.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            
            Text(squad.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if !squad.description.isEmpty {
                Text(squad.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 20) {
                Label("\(squad.memberCount) membre\(squad.memberCount > 1 ? "s" : "")", systemImage: "person.3.fill")
                    .font(.caption)
                    .foregroundColor(.coralAccent)
                
                if squad.hasActiveSessions {
                    Label("Session active", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Invite Code Section
    
    private var inviteCodeSection: some View {
        VStack(spacing: 8) {
            Text("Code d'invitation")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 16) {
                Text(squad.inviteCode)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(4)
                
                Button {
                    UIPasteboard.general.string = squad.inviteCode
                } label: {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(.coralAccent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Bouton Démarrer Session (si admin/coach)
            if canStartSession {
                Button {
                    showStartSession = true
                } label: {
                    Label("Démarrer une session", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.coralAccent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            // Bouton Quitter Squad
            Button {
                showLeaveConfirmation = true
            } label: {
                Label("Quitter la squad", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
            .disabled(isLeaving)
            .opacity(isLeaving ? 0.5 : 1)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canStartSession: Bool {
        guard let userId = AuthService.shared.currentUserId else { return false }
        return squad.canCreateSession(userId: userId)
    }
    
    // MARK: - Members Section
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Membres")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(Array(squad.members.keys.prefix(10)), id: \.self) { userId in
                    if let role = squad.members[userId] {
                        MemberRow(userId: userId, role: role, isCreator: userId == squad.creatorId)
                    }
                }
                
                if squad.memberCount > 10 {
                    Text("+ \(squad.memberCount - 10) autres membres")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiques")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Sessions
                SquadStatCard(title: "Sessions", value: "0", icon: "figure.run")
                
                // Distance
                SquadStatCard(title: "Distance", value: "0 km", icon: "location.fill")
            }
        }
    }
}

// MARK: - Member Row

private struct MemberRow: View {
    let userId: String
    let role: SquadMemberRole
    let isCreator: Bool
    
    @State private var displayName: String = "Chargement..."
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(roleColor.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(roleColor)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Text(roleLabel)
                        .font(.caption)
                        .foregroundColor(roleColor)
                    
                    if isCreator {
                        Text("• Créateur")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: roleIcon)
                .foregroundColor(roleColor)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await loadUserName()
        }
    }
    
    private var roleColor: Color {
        switch role {
        case .admin: return .coralAccent
        case .coach: return .purple
        case .member: return .blueAccent
        }
    }
    
    private var roleLabel: String {
        switch role {
        case .admin: return "Admin"
        case .coach: return "Coach"
        case .member: return "Membre"
        }
    }
    
    private var roleIcon: String {
        switch role {
        case .admin: return "star.fill"
        case .coach: return "whistle"
        case .member: return "person.fill"
        }
    }
    
    private func loadUserName() async {
        do {
            if let user = try await AuthService.shared.getUserProfile(userId: userId) {
                displayName = user.displayName
            }
        } catch {
            displayName = "Utilisateur #\(userId.prefix(6))"
        }
    }
}

// MARK: - Stat Card (renommé localement pour éviter les collisions)

private struct SquadStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.coralAccent)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
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
    NavigationStack {
        SquadDetailView(squad: SquadModel(
            name: "Marathon Paris 2024",
            description: "Préparation collective pour le marathon de Paris",
            inviteCode: "ABC123",
            creatorId: "user1",
            members: [
                "user1": .admin,
                "user2": .member,
                "user3": .member
            ]
        ))
    }
    .preferredColorScheme(.dark)
}
