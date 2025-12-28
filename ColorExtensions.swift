//
//  ColorExtensions.swift
//  RunningMan
//
//  Extensions de couleurs pour le design system
//

import SwiftUI

extension Color {
    // MARK: - App Colors (à ajouter dans Assets.xcassets aussi)
    
    /// Navy foncé pour le fond principal
    static let darkNavy = Color(red: 0.11, green: 0.14, blue: 0.2) // #1C2433
    
    /// Coral pour les accents principaux
    static let coralAccent = Color(red: 1.0, green: 0.42, blue: 0.42) // #FF6B6B
    
    /// Rose pour les accents secondaires
    static let pinkAccent = Color(red: 0.93, green: 0.35, blue: 0.62) // #ED599F
    
    /// Bleu pour les informations
    static let blueAccent = Color(red: 0.28, green: 0.67, blue: 0.93) // #47ABEE
    
    /// Jaune pour les warnings/achievements
    static let yellowAccent = Color(red: 0.98, green: 0.8, blue: 0.27) // #FACC45
    
    /// Vert pour les succès/actions positives
    static let greenAccent = Color(red: 0.34, green: 0.82, blue: 0.58) // #57D194
    
    /// Purple pour les accents violets
    static let purpleAccent = Color(red: 0.54, green: 0.39, blue: 0.92) // #8A63EB
    
    // MARK: - Gradient Helpers
    
    /// Dégradé orange -> rose (pour les barres de progression)
    static let progressGradient = LinearGradient(
        colors: [.orange, Color(red: 0.93, green: 0.35, blue: 0.62)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Dégradé bleu -> violet (pour les badges de participants)
    static let participantGradient = LinearGradient(
        colors: [Color(red: 0.28, green: 0.67, blue: 0.93), Color(red: 0.54, green: 0.39, blue: 0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Dégradé vert pour les boutons d'action
    static let actionGradient = LinearGradient(
        colors: [Color(red: 0.34, green: 0.82, blue: 0.58), Color(red: 0.24, green: 0.72, blue: 0.48)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Shadow Styles

extension View {
    /// Ombre pour les cartes glassmorphism
    func glassShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    /// Ombre pour les boutons
    func buttonShadow(color: Color = .black) -> some View {
        self.shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    
    /// Ombre douce pour les éléments de la carte
    func mapElementShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Material Styles

extension View {
    /// Applique un fond glassmorphism avec bordure
    func glassBackground(
        cornerRadius: CGFloat = 20,
        borderColor: Color = Color.white.opacity(0.1),
        borderWidth: CGFloat = 1
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
            .glassShadow()
    }
}

// MARK: - Typography Styles

extension Font {
    /// Titre principal (gros et bold)
    static let appTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    
    /// Titre de section
    static let sectionTitle = Font.system(size: 20, weight: .bold, design: .default)
    
    /// Sous-titre
    static let subtitle = Font.system(size: 16, weight: .semibold, design: .default)
    
    /// Corps de texte
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    
    /// Texte secondaire
    static let caption = Font.system(size: 13, weight: .medium, design: .default)
    
    /// Petits labels
    static let smallLabel = Font.system(size: 11, weight: .medium, design: .default)
    
    /// Chiffres/Stats (pour les distances, temps, etc.)
    static func stat(size: CGFloat = 32) -> Font {
        Font.system(size: size, weight: .bold, design: .rounded)
    }
}

// MARK: - Spacing

enum Spacing {
    /// Espacement extra small (4pt)
    static let xs: CGFloat = 4
    
    /// Espacement small (8pt)
    static let sm: CGFloat = 8
    
    /// Espacement medium (12pt)
    static let md: CGFloat = 12
    
    /// Espacement large (16pt)
    static let lg: CGFloat = 16
    
    /// Espacement extra large (20pt)
    static let xl: CGFloat = 20
    
    /// Espacement 2x extra large (24pt)
    static let xxl: CGFloat = 24
    
    /// Espacement 3x extra large (32pt)
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius

enum CornerRadius {
    /// Petit rayon (8pt)
    static let small: CGFloat = 8
    
    /// Moyen rayon (12pt)
    static let medium: CGFloat = 12
    
    /// Grand rayon (16pt)
    static let large: CGFloat = 16
    
    /// Extra grand rayon (20pt)
    static let xlarge: CGFloat = 20
    
    /// Rayon pour boutons (24pt)
    static let button: CGFloat = 24
}
