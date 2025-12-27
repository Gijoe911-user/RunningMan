//
//  ColorGuide.swift
//  RunningMan
//
//  Guide et extensions pour la palette de couleurs Dark Mode néon
//

/*
 ═══════════════════════════════════════════════════════════════════════════
 GUIDE : CRÉER LES COULEURS DANS L'ASSET CATALOG (OPTIONNEL)
 ═══════════════════════════════════════════════════════════════════════════
 
 Les couleurs ci-dessous fonctionnent automatiquement avec des fallbacks.
 Mais pour une meilleure pratique, créez-les dans Assets.xcassets :
 
 1. Ouvrez Assets.xcassets dans Xcode
 2. Clic droit → "New Color Set"
 3. Nommez la couleur selon le nom ci-dessous
 4. Configurez les valeurs RGB/Hex
 
 ───────────────────────────────────────────────────────────────────────────
 COLOR SETS À CRÉER :
 ───────────────────────────────────────────────────────────────────────────
 
 DarkNavy (Fond principal)
   • Hex: #1A1F3A
   • RGB: R:26, G:31, B:58
   • Usage: Fond principal de l'app
 
 CoralAccent (Accent principal - Coureurs)
   • Hex: #FF6B6B
   • RGB: R:255, G:107, B:107
   • Usage: Actions principales, icônes coureurs
 
 PinkAccent (Accent secondaire)
   • Hex: #FF85A1
   • RGB: R:255, G:133, B:161
   • Usage: Accents secondaires, highlights
 
 BlueAccent (Supporters)
   • Hex: #4ECDC4
   • RGB: R:78, G:205, B:196
   • Usage: Icônes supporters, sections support
 
 PurpleAccent
   • Hex: #9B59B6
   • RGB: R:155, G:89, B:182
   • Usage: Accents tertiaires, variété visuelle
 
 GreenAccent (Actif/En ligne)
   • Hex: #2ECC71
   • RGB: R:46, G:204, B:113
   • Usage: Statut actif, succès, en ligne
 
 YellowAccent (Avertissements/Objectifs)
   • Hex: #F1C40F
   • RGB: R:241, G:196, B:15
   • Usage: Avertissements, objectifs, alertes
 
 ═══════════════════════════════════════════════════════════════════════════
 
 Note: Même sans créer ces couleurs dans l'Asset Catalog, 
 l'app fonctionnera grâce aux fallbacks automatiques ci-dessous.
 
 ═══════════════════════════════════════════════════════════════════════════
*/

import SwiftUI

// MARK: - Color Extensions avec Fallbacks Automatiques
extension Color {
    
    // MARK: - Couleurs Principales
    
    /// Fond principal dark navy (#1A1F3A)
    /// Cherche d'abord dans l'Asset Catalog, sinon utilise la valeur hardcodée
    static var darkNavy: Color {
        if let assetColor = Self.fromAssetCatalog("DarkNavy") {
            return assetColor
        }
        return Color(red: 0.102, green: 0.122, blue: 0.227)
    }
    
    /// Accent principal coral (#FF6B6B) - pour coureurs
    /// Cherche d'abord dans l'Asset Catalog, sinon utilise la valeur hardcodée
    static var coralAccent: Color {
        if let assetColor = Self.fromAssetCatalog("CoralAccent") {
            return assetColor
        }
        return Color(red: 1.0, green: 0.42, blue: 0.42)
    }
    
    /// Accent secondaire pink (#FF85A1)
    /// Cherche d'abord dans l'Asset Catalog, sinon utilise la valeur hardcodée
    static var pinkAccent: Color {
        if let assetColor = Self.fromAssetCatalog("PinkAccent") {
            return assetColor
        }
        return Color(red: 1.0, green: 0.522, blue: 0.631)
    }
    
    /// Accent blue (#4ECDC4) - pour supporters
    /// Cherche d'abord dans l'Asset Catalog, sinon utilise la valeur hardcodée
    static var blueAccent: Color {
        if let assetColor = Self.fromAssetCatalog("BlueAccent") {
            return assetColor
        }
        return Color(red: 0.306, green: 0.804, blue: 0.769)
    }
    
    /// Accent purple (#9B59B6)
    /// Cherche d'abord dans l'Asset Catalog, sinon utilise la valeur hardcodée
    static var purpleAccent: Color {
        if let assetColor = Self.fromAssetCatalog("PurpleAccent") {
            return assetColor
        }
        return Color(red: 0.608, green: 0.349, blue: 0.714)
    }
    
    /// Accent green (#2ECC71) - pour statut actif/en ligne
    /// Cherche d'abord dans l'Asset Catalog, sinon utilise la valeur hardcodée
    static var greenAccent: Color {
        if let assetColor = Self.fromAssetCatalog("GreenAccent") {
            return assetColor
        }
        return Color(red: 0.18, green: 0.8, blue: 0.443)
    }
    
    /// Accent yellow (#F1C40F) - pour avertissements/objectifs
    /// Cherche d'abord dans l'Asset Catalog, sinon utilise la valeur hardcodée
    static var yellowAccent: Color {
        if let assetColor = Self.fromAssetCatalog("YellowAccent") {
            return assetColor
        }
        return Color(red: 0.945, green: 0.769, blue: 0.059)
    }
    
    // MARK: - Helpers
    
    /// Tente de charger une couleur depuis l'Asset Catalog
    /// Retourne nil si la couleur n'existe pas
    private static func fromAssetCatalog(_ name: String) -> Color? {
        #if canImport(UIKit)
        guard UIColor(named: name) != nil else { return nil }
        return Color(name)
        #elseif canImport(AppKit)
        guard NSColor(named: name) != nil else { return nil }
        return Color(name)
        #else
        return nil
        #endif
    }
    
    /// Crée une couleur depuis un code hexadécimal
    /// - Parameter hex: Code hex (ex: "FF6B6B", "#FF6B6B", "F00")
    /// - Returns: Couleur SwiftUI correspondante
    ///
    /// Exemples d'utilisation:
    /// ```swift
    /// Color.hex("FF6B6B")     // RGB 24-bit
    /// Color.hex("#FF6B6B")    // Avec #
    /// Color.hex("F00")        // RGB 12-bit
    /// Color.hex("80FF6B6B")   // ARGB 32-bit avec alpha
    /// ```
    static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Usage Examples
/*
 ═══════════════════════════════════════════════════════════════════════════
 EXEMPLES D'UTILISATION :
 ═══════════════════════════════════════════════════════════════════════════
 
 // Dans vos vues SwiftUI:
 
 Text("Hello")
     .foregroundColor(.coralAccent)
 
 Circle()
     .fill(.darkNavy)
 
 Rectangle()
     .fill(.greenAccent)
 
 // Avec hex:
 Text("Custom")
     .foregroundColor(.hex("#FF6B6B"))
 
 ═══════════════════════════════════════════════════════════════════════════
*/
