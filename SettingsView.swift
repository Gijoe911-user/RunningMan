//
//  SettingsView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue des paramètres de l'application
/// TODO: Implémenter les préférences utilisateur
struct SettingsView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var unitsMetric = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                List {
                    // Section Notifications
                    Section {
                        Toggle("Notifications activées", isOn: $notificationsEnabled)
                    } header: {
                        Text("Notifications")
                    }
                    
                    // Section Unités
                    Section {
                        Toggle("Système métrique (km)", isOn: $unitsMetric)
                    } header: {
                        Text("Unités")
                    }
                    
                    // ✅ SECTION DEBUG (temporaire)
                    #if DEBUG
                    Section {
                        NavigationLink {
                            DebugCleanupView()
                        } label: {
                            HStack {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading) {
                                    Text("Nettoyage & Debug")
                                        .fontWeight(.semibold)
                                    Text("Réparer les sessions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("🔧 Développement")
                    } footer: {
                        Text("Cette section est visible uniquement en mode debug")
                            .font(.caption)
                    }
                    #endif
                    
                    // Section À propos
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("À propos")
                    }
                }
                .scrollContentBackground(.hidden)
                .tint(.coralAccent)
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                }
            }
        }
    }
}

// MARK: - Debug Cleanup View

#if DEBUG
struct DebugCleanupView: View {
    @State private var isWorking = false
    @State private var resultMessage = ""
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            List {
                Section("🚨 Actions urgentes") {
                    Button {
                        Task {
                            await forceEndAllSessions()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(.red)
                            Text("Terminer TOUTES les sessions actives")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isWorking)
                }
                
                Section("🔧 Informations") {
                    Button {
                        Task {
                            await listAllSessions()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Lister toutes les sessions actives")
                        }
                    }
                    .disabled(isWorking)
                }
                
                if isWorking {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Traitement en cours...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !resultMessage.isEmpty {
                    Section("Résultat") {
                        Text(resultMessage)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("🧹 Nettoyage")
    }
    
    private func forceEndAllSessions() async {
        isWorking = true
        resultMessage = ""
        
        do {
            let count = try await SessionCleanupUtility.shared.forceEndAllActiveSessions()
            resultMessage = "✅ \(count) session(s) terminée(s) avec succès !"
        } catch {
            resultMessage = "❌ Erreur : \(error.localizedDescription)"
        }
        
        isWorking = false
    }
    
    private func listAllSessions() async {
        isWorking = true
        resultMessage = ""
        
        do {
            let sessions = try await SessionCleanupUtility.shared.listActiveSessions()
            
            if sessions.isEmpty {
                resultMessage = "✅ Aucune session active trouvée"
            } else {
                var message = "📋 Sessions actives trouvées :\n\n"
                for (id, info) in sessions {
                    message += "ID: \(id)\n"
                    message += "Status: \(info["status"] ?? "?")\n"
                    message += "Squad: \(info["squadId"] ?? "?")\n"
                    message += "Démarrée: \(info["startedAt"] ?? "?")\n"
                    message += "Durée: \(info["elapsedTime"] ?? "?")\n"
                    message += "---\n"
                }
                resultMessage = message
            }
        } catch {
            resultMessage = "❌ Erreur : \(error.localizedDescription)"
        }
        
        isWorking = false
    }
}
#endif

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
