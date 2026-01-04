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
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SquadViewModel.self) private var squadVM
    @Environment(AppState.self) private var appState
    
    @State private var showLeaveConfirmation = false
    @State private var showStartSession = false
    @State private var isLeaving = false
    @State private var errorMessage: String?
    @State private var copiedToClipboard = false
    @State private var showShareSheet = false
    @State private var showSessionsList = false
    
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
            .refreshable {
                // ✅ Invalider le cache lors du pull-to-refresh
                if let squadId = squad.id {
                    SessionService.shared.invalidateCache(squadId: squadId)
                    Logger.log("[AUDIT-SDV-01] 🔄 SquadDetailView - Cache invalidé", category: .ui)
                }
            }
        }
        .navigationTitle(squad.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.coralAccent)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
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
            CreateSessionView(squad: squad) {
                // ✅ Callback : Redirection avec délai pour transition fluide
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    appState.selectedTab = 2 // Redirection vers l'onglet Sessions (Course)
                }
            }
        }
        .navigationDestination(isPresented: $showSessionsList) {
            SquadSessionsListView(squad: squad)
        }
        .task {
            // Définir le contexte du service de localisation en temps réel
            if let squadId = squad.id {
                RealtimeLocationService.shared.setContext(squadId: squadId)
                Logger.log("[AUDIT-SDV-02] 🎯 SquadDetailView.task - Contexte défini pour squad: \(squadId)", category: .location)
            }
        }
    }
    
    // MARK: - Actions
    
    private var shareText: String {
        "Rejoins mon squad '\(squad.name)' sur RunningMan ! 🏃\nCode d'invitation : \(squad.inviteCode)"
    }
    
    private func leaveSquad() {
        guard let userId = AuthService.shared.currentUserId else { return }
        
        isLeaving = true
        
        Task {
            do {
                if let squadId = squad.id {
                    try await SquadService.shared.leaveSquad(squadId: squadId, userId: userId)
                    
                    // Recharger les squads dans le ViewModel
                    await squadVM.loadUserSquads()
                    
                    // Fermer la vue détail
                    dismiss()
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
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Code d'invitation")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Partagez ce code avec vos amis")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                Text(squad.inviteCode)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.coralAccent)
                    .tracking(4)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = squad.inviteCode
                    copiedToClipboard = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Reset after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedToClipboard = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                            .font(.title3)
                        if copiedToClipboard {
                            Text("Copié")
                                .font(.caption.bold())
                        }
                    }
                    .foregroundColor(copiedToClipboard ? .greenAccent : .coralAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(copiedToClipboard ? Color.greenAccent.opacity(0.2) : Color.coralAccent.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Bouton Voir les sessions
            Button {
                showSessionsList = true
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("Voir les sessions")
                    Spacer()
                    if squad.hasActiveSessions {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal)
                .background(
                    LinearGradient(
                        colors: [Color.purpleAccent, Color.blueAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Bouton Partager
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Partager le code")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.blueAccent, Color.purpleAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Bouton Démarrer Session (TOUS les membres peuvent créer)
            Button {
                showStartSession = true
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Démarrer une session")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Bouton Quitter Squad
            if !isCreator {
                Button {
                    showLeaveConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Quitter la squad")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLeaving)
                .opacity(isLeaving ? 0.5 : 1)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isCreator: Bool {
        guard let userId = AuthService.shared.currentUserId else { return false }
        return squad.creatorId == userId
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

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
