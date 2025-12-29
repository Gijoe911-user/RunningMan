//
//  SessionHistoryView.swift
//  RunningMan
//
//  Vue pour afficher l'historique des sessions terminées
//

import SwiftUI
import FirebaseFirestore

struct SessionHistoryView: View {
    let squadId: String
    
    @State private var sessions: [SessionModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .tint(.coralAccent)
            } else if sessions.isEmpty {
                emptyState
            } else {
                sessionsList
            }
        }
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSessions()
        }
        .refreshable {
            await loadSessions()
        }
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionHistoryDetailMapView(session: session)) {
                        SessionHistoryCard(session: session)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.coralAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Aucune session passée")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Les sessions terminées apparaîtront ici")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    // MARK: - Load Sessions
    
    private func loadSessions() async {
        isLoading = true
        
        do {
            let db = Firestore.firestore()
            let query = db.collection("sessions")
                .whereField("squadId", isEqualTo: squadId)
                .whereField("status", isEqualTo: SessionStatus.ended.rawValue)
                .order(by: "endedAt", descending: true)
                .limit(to: 50)
            
            let snapshot = try await query.getDocuments()
            sessions = snapshot.documents.compactMap { try? $0.data(as: SessionModel.self) }
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Session History Card

struct SessionHistoryCard: View {
    let session: SessionModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionDate)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(sessionTime)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Label(session.activityType.displayName, systemImage: session.activityType.icon)
                    .font(.caption)
                    .foregroundColor(.coralAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.coralAccent.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Stats
            HStack(spacing: 20) {
                StatItem(
                    icon: "figure.run",
                    value: "\(session.participants.count)",
                    label: "Coureurs"
                )
                
                StatItem(
                    icon: "location.fill",
                    value: String(format: "%.2f km", session.distanceInKilometers),
                    label: "Distance"
                )
                
                StatItem(
                    icon: "clock.fill",
                    value: session.formattedDuration,
                    label: "Durée"
                )
                
                StatItem(
                    icon: "speedometer",
                    value: session.averagePaceMinPerKm,
                    label: "Allure"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var sessionDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: session.startedAt)
    }
    
    private var sessionTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.startedAt)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.coralAccent)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionHistoryView(squadId: "squad1")
    }
    .preferredColorScheme(.dark)
}
