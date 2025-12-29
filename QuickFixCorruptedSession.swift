//
//  QuickFixCorruptedSession.swift
//  RunningMan
//
//  Script one-shot pour supprimer la session corrompue BiKLs6aExrcRkF9Xqr9k
//

import Foundation
import SwiftUI
import FirebaseFirestore

/// ⚡️ Fix rapide pour supprimer la session corrompue
///
/// **Usage :**
/// ```swift
/// Button("🔥 FIX RAPIDE") {
///     Task {
///         await QuickFixCorruptedSession.run()
///     }
/// }
/// ```
@MainActor
struct QuickFixCorruptedSession {
    
    private static let corruptedSessionId = "BiKLs6aExrcRkF9Xqr9k"
    
    static func run() async {
        print("🔥 ============================================")
        print("🔥 SUPPRESSION DE LA SESSION CORROMPUE")
        print("🔥 ============================================")
        print("")
        
        let db = Firestore.firestore()
        let sessionRef = db.collection("sessions").document(corruptedSessionId)
        
        // 1. Vérifier si elle existe
        print("🔍 Vérification de l'existence de la session...")
        
        do {
            let document = try await sessionRef.getDocument()
            
            if !document.exists {
                print("✅ La session n'existe plus (déjà supprimée)")
                print("")
                return
            }
            
            print("⚠️  Session trouvée dans Firestore")
            
            // 2. Récupérer le squadId pour nettoyer
            if let data = document.data(),
               let squadId = data["squadId"] as? String {
                print("📋 SquadId détecté: \(squadId)")
                
                // 3. Retirer de la squad
                print("🧹 Nettoyage de la squad...")
                let squadRef = db.collection("squads").document(squadId)
                try await squadRef.updateData([
                    "activeSessions": FieldValue.arrayRemove([corruptedSessionId])
                ])
                print("✅ Session retirée de la squad")
            }
            
            // 4. Supprimer le document
            print("🗑️  Suppression du document...")
            try await sessionRef.delete()
            print("✅ Document supprimé avec succès")
            
            // 5. Invalider le cache
            print("🔄 Invalidation du cache...")
            SessionService.shared.invalidateCache()
            print("✅ Cache invalidé")
            
            print("")
            print("🎉 ============================================")
            print("🎉 SESSION CORROMPUE SUPPRIMÉE AVEC SUCCÈS !")
            print("🎉 ============================================")
            print("")
            print("✅ Vous pouvez maintenant :")
            print("   - Créer de nouvelles sessions")
            print("   - Voir les sessions actives")
            print("   - Utiliser le bouton Terminer")
            print("")
            
        } catch {
            print("❌ ERREUR : \(error.localizedDescription)")
            print("")
            print("⚠️  Solution alternative :")
            print("   1. Ouvrez Firebase Console")
            print("   2. Allez dans Firestore Database")
            print("   3. Collection 'sessions'")
            print("   4. Supprimez le document '\(corruptedSessionId)'")
            print("")
        }
    }
}

// MARK: - Extension pour faciliter l'usage

#if DEBUG
extension View {
    /// Ajoute un bouton de fix rapide dans le toolbar
    func withQuickFixButton() -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        await QuickFixCorruptedSession.run()
                    }
                } label: {
                    Image(systemName: "bandage.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
}
#endif
