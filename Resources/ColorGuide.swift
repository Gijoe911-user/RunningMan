//
//  ColorGuide.swift
//  RunningMan
//
//  Guide pour la palette de couleurs - DOCUMENTATION SEULEMENT
//
//  ⚠️ Les couleurs sont définies dans ColorExtensions.swift
//  Ce fichier contient uniquement la documentation de référence

/*
 ═══════════════════════════════════════════════════════════════════════════
 GUIDE : CRÉER LES COULEURS DANS L'ASSET CATALOG (OPTIONNEL)
 ═══════════════════════════════════════════════════════════════════════════
 
 Les couleurs sont définies dans ColorExtensions.swift avec des fallbacks.
 Vous pouvez optionnellement les créer dans Assets.xcassets :
 
 1. Ouvrez Assets.xcassets dans Xcode
 2. Clic droit → "New Color Set"
 3. Nommez la couleur selon le nom ci-dessous
 4. Configurez les valeurs RGB/Hex
 
 ───────────────────────────────────────────────────────────────────────────
 COLOR SETS DISPONIBLES :
 ───────────────────────────────────────────────────────────────────────────
 
 DarkNavy (Fond principal)
   • Hex: #1C2433
   • RGB: R:28, G:36, B:51
   • Usage: Fond principal de l'app
 
 CoralAccent (Accent principal)
   • Hex: #FF6B6B
   • RGB: R:255, G:107, B:107
   • Usage: Actions principales, icônes coureurs
 
 PinkAccent (Accent secondaire)
   • Hex: #ED599F
   • RGB: R:237, G:89, B:159
   • Usage: Accents secondaires, dégradés
 
 BlueAccent (Informations)
   • Hex: #47ABEE
   • RGB: R:71, G:171, B:238
   • Usage: Informations, statistiques
 
 YellowAccent (Achievements/Warnings)
   • Hex: #FACC45
   • RGB: R:250, G:204, B:69
   • Usage: Warnings, achievements
 
 GreenAccent (Succès/Actif)
   • Hex: #57D194
   • RGB: R:87, G:209, B:148
   • Usage: Statut actif, succès, actions positives
 
 ═══════════════════════════════════════════════════════════════════════════
 UTILISATION DANS LE CODE
 ═══════════════════════════════════════════════════════════════════════════
 
 import SwiftUI
 
 // Utiliser les couleurs
 Color.darkNavy        // Fond principal
 Color.coralAccent     // Accent principal
 Color.pinkAccent      // Accent secondaire
 Color.blueAccent      // Informations
 Color.yellowAccent    // Warnings/Achievements
 Color.greenAccent     // Succès
 
 // Dégradés prédéfinis
 Color.progressGradient      // Orange → Rose
 Color.participantGradient   // Bleu → Violet
 Color.actionGradient        // Vert clair → Vert foncé
 
 ═══════════════════════════════════════════════════════════════════════════
*/

import SwiftUI

// Ce fichier contient uniquement la documentation
// Les couleurs sont définies dans ColorExtensions.swift



