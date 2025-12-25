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

// MARK: - Preview

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
