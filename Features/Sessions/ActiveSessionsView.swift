//
//  ActiveSessionsView.swift
//  RunningMan
//
//  Vue pour afficher toutes les sessions actives
//

import SwiftUI
import CoreLocation

struct ActiveSessionsView: View {
    @Environment(SquadViewModel.self) private var squadVM
    @State private var showLocationPermissionAlert = false
    @State private var activeSessions: [SessionModel] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .tint(.coralAccent)
                                .padding(.top, 40)
                        } else if activeSessions.isEmpty {
                            emptyStateView
                        } else {
                            sessionsList
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Sessions actives")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadActiveSessions()
            }
            .alert("Localisation requise", isPresented: $showLocationPermissionAlert) {
                Button("Paramètres", role: .cancel) {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Plus tard", role: .cancel) { }
            } message: {
                Text("Pour visualiser la carte et suivre les coureurs en temps réel, nous avons besoin d'accéder à votre localisation.")
            }
            .onAppear {
                Task {
                    await loadActiveSessions()
                    checkLocationPermission()
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Aucune session active")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Les sessions de vos squads apparaîtront ici")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        VStack(spacing: 12) {
            ForEach(activeSessions) { session in
                NavigationLink {
                    ActiveSessionDetailView(session: session)
                } label: {
                    SessionCard(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Load Active Sessions
    
    private func loadActiveSessions() async {
        isLoading = true
        
        // Charger les sessions actives de tous les squads de l'utilisateur
        var allSessions: [SessionModel] = []
        
        for squad in squadVM.userSquads {
            guard let squadId = squad.id else { continue }
            
            do {
                if let session = try await SessionService.shared.getActiveSession(squadId: squadId) {
                    allSessions.append(session)
                }
            } catch {
                print("Error loading active session for squad \(squadId): \(error)")
            }
        }
        
        activeSessions = allSessions
        isLoading = false
    }
    
    // MARK: - Location Permission Check
    
    private func checkLocationPermission() {
        // Vérifier si les permissions de localisation sont accordées
        // Si non, afficher l'alerte
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .denied || status == .restricted {
            showLocationPermissionAlert = true
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: SessionModel
    @State private var squadName: String = "Chargement..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
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
                        Image(systemName: "figure.run")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(squadName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("En cours")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Stats
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blueAccent)
                    Text("\(session.participants.count) participant\(session.participants.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.coralAccent)
                    Text(formatDuration(session.startedAt))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            await loadSquadName()
        }
    }
    
    private func loadSquadName() async {
        do {
            if let squad = try await SquadService.shared.getSquad(squadId: session.squadId) {
                squadName = squad.name
            }
        } catch {
            squadName = "Squad"
        }
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

#Preview {
    ActiveSessionsView()
        .preferredColorScheme(.dark)
}
