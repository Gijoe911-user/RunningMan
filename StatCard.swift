//
//  StatCard.swift
//  RunningMan
//
//  Composant réutilisable pour afficher des statistiques
//  Supporte deux styles : compact (tracking) et complet (profil)
//

import SwiftUI

/// Carte de statistique réutilisable avec deux styles
struct StatCard: View {
    
    // MARK: - Style
    
    enum Style {
        /// Style compact pour le tracking (petit, sans couleur)
        case compact
        /// Style complet pour le profil (avec icône et couleur)
        case full
    }
    
    // MARK: - Properties
    
    let title: String
    let value: String
    let unit: String
    let icon: String
    let style: Style
    let color: Color?
    
    // MARK: - Initializers
    
    /// Initialisation pour le style tracking (compact)
    /// - Parameters:
    ///   - title: Titre de la stat (ex: "Distance")
    ///   - value: Valeur (ex: "12.5")
    ///   - unit: Unité (ex: "km")
    ///   - icon: Icône SF Symbol (ex: "figure.run")
    init(
        title: String,
        value: String,
        unit: String = "",
        icon: String
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.style = .compact
        self.color = nil
    }
    
    /// Initialisation pour le style profil (complet avec couleur)
    /// - Parameters:
    ///   - icon: Icône SF Symbol
    ///   - value: Valeur principale
    ///   - unit: Unité optionnelle
    ///   - label: Label descriptif
    ///   - color: Couleur de l'icône
    init(
        icon: String,
        value: String,
        unit: String = "",
        label: String,
        color: Color
    ) {
        self.icon = icon
        self.value = value
        self.unit = unit
        self.title = label
        self.style = .full
        self.color = color
    }
    
    // MARK: - Body
    
    var body: some View {
        switch style {
        case .compact:
            compactCard
        case .full:
            fullCard
        }
    }
    
    // MARK: - Compact Style (Tracking)
    
    private var compactCard: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Full Style (Profile)
    
    private var fullCard: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color ?? .blue)
            
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview("Compact Style") {
    HStack(spacing: 20) {
        StatCard(
            title: "Distance",
            value: "12.5",
            unit: "km",
            icon: "figure.run"
        )
        
        StatCard(
            title: "Durée",
            value: "1:23:45",
            unit: "",
            icon: "timer"
        )
        
        StatCard(
            title: "Allure",
            value: "5:30",
            unit: "/km",
            icon: "speedometer"
        )
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}

#Preview("Full Style") {
    VStack {
        HStack(spacing: 12) {
            StatCard(
                icon: "figure.run",
                value: "24",
                label: "Courses",
                color: .orange
            )
            
            StatCard(
                icon: "map",
                value: "125",
                unit: "km",
                label: "Distance",
                color: .blue
            )
            
            StatCard(
                icon: "timer",
                value: "18h",
                label: "Durée",
                color: .purple
            )
        }
    }
    .padding()
    .background(Color.black)
}
