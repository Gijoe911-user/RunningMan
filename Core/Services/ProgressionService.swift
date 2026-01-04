//
//  ProgressionService.swift
//  RunningMan
//
//  Service de gestion de la progression et gamification
//

import Foundation
import FirebaseFirestore
import Combine

/// Service de gestion de la progression et gamification
///
/// Calcule l'indice de consistance, gère les objectifs hebdomadaires,
/// et fournit les données pour les badges/achievements.
///
/// **Responsabilités :**
/// - Calcul du taux de consistance (`objectifsRéalisés / objectifsTentés`)
/// - Mise à jour des objectifs hebdomadaires après chaque session
/// - Création automatique d'objectifs hebdomadaires
/// - Détermination de la couleur de progression (Vert/Jaune/Rouge)
///
/// **Formules :**
/// ```
/// consistencyRate = Σ(objectifsComplétés) / Σ(objectifsTentés)
/// couleur = Vert (≥75%) | Jaune (50-75%) | Rouge (<50%)
/// ```
///
/// - Important: Ce service doit être appelé après chaque session terminée
///   pour maintenir les stats à jour.
///
/// - SeeAlso: `UserModel.consistencyRate`, `WeeklyGoal`
@MainActor
final class ProgressionService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ProgressionService()
    
    // MARK: - Published State
    
    /// Taux de consistance actuel (0.0 - 1.0)
    @Published private(set) var consistencyRate: Double = 0.0
    
    /// Objectifs de la semaine en cours
    @Published private(set) var currentWeekGoals: [WeeklyGoal] = []
    
    /// Indique si un calcul est en cours
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        Logger.log("📊 ProgressionService initialisé", category: .service)
    }
    
    // MARK: - Public API
    
    /// Calcule l'indice de consistance pour un utilisateur
    ///
    /// Formule : `consistencyRate = objectifsRéalisés / objectifsTentés`
    ///
    /// **Algorithme :**
    /// 1. Récupère tous les objectifs des 12 dernières semaines
    /// 2. Filtre les objectifs avec `targetValue > 0` (tentés)
    /// 3. Compte les objectifs avec `isCompleted == true`
    /// 4. Calcule le ratio
    ///
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: Taux de consistance entre 0.0 et 1.0
    /// - Throws: `ProgressionError` si échec de calcul
    func calculateConsistencyRate(for userId: String) async throws -> Double {
        Logger.log("📊 Calcul consistance pour user: \(userId)", category: .service)
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Récupérer l'utilisateur
            let userDoc = try await db.collection("users").document(userId).getDocument()
            guard let user = try? userDoc.data(as: UserModel.self) else {
                throw ProgressionError.userNotFound
            }
            
            // Filtrer les objectifs des 12 dernières semaines
            let twelveWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date()) ?? Date()
            let recentGoals = (user.weeklyGoals ?? []).filter { $0.weekStartDate >= twelveWeeksAgo }
            
            guard !recentGoals.isEmpty else {
                Logger.log("ℹ️ Aucun objectif récent trouvé", category: .service)
                return 0.0
            }
            
            // Compter les objectifs tentés et réalisés
            let attemptedGoals = recentGoals.filter { $0.targetValue > 0 }
            let completedGoals = attemptedGoals.filter { $0.isCompleted }
            
            guard !attemptedGoals.isEmpty else {
                return 0.0
            }
            
            let rate = Double(completedGoals.count) / Double(attemptedGoals.count)
            
            Logger.logSuccess(
                "✅ Consistance calculée: \(Int(rate * 100))% (\(completedGoals.count)/\(attemptedGoals.count))",
                category: .service
            )
            
            // Mettre à jour le cache local
            await MainActor.run {
                self.consistencyRate = rate
            }
            
            // Mettre à jour dans Firestore
            try await db.collection("users").document(userId).updateData([
                "consistencyRate": rate,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            return rate
            
        } catch {
            Logger.logError(error, context: "calculateConsistencyRate", category: .service)
            throw ProgressionError.calculationFailed(error)
        }
    }
    
    /// Met à jour les objectifs hebdomadaires après une session
    ///
    /// Appelé automatiquement par `SessionService.endSession()`.
    ///
    /// **Logique :**
    /// 1. Récupère les objectifs de la semaine en cours
    /// 2. Pour chaque objectif non complété :
    ///    - Ajoute la distance/durée de la session
    ///    - Marque comme complété si seuil atteint
    /// 3. Sauvegarde dans Firestore
    /// 4. Recalcule le taux de consistance
    ///
    /// - Parameters:
    ///   - userId: ID de l'utilisateur
    ///   - session: Session terminée
    /// - Throws: `ProgressionError` si mise à jour échoue
    func updateWeeklyGoals(for userId: String, with session: SessionModel) async throws {
        Logger.log("📊 Mise à jour objectifs hebdo pour session: \(session.id ?? "unknown")", category: .service)
        
        guard let sessionId = session.id else {
            throw ProgressionError.invalidSession
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Récupérer l'utilisateur
            let userDoc = try await db.collection("users").document(userId).getDocument()
            var user = try userDoc.data(as: UserModel.self)
            
            // Identifier la semaine en cours
            let startOfWeek = Calendar.current.startOfWeek(for: Date())
            
            // Filtrer les objectifs de cette semaine
            var weekGoals = (user.weeklyGoals ?? []).filter {
                Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .weekOfYear)
            }
            
            // Si aucun objectif cette semaine, ne rien faire (l'utilisateur n'en a pas créé)
            guard !weekGoals.isEmpty else {
                Logger.log("ℹ️ Aucun objectif pour cette semaine", category: .service)
                return
            }
            
            // Mettre à jour chaque objectif
            var updated = false
            for i in 0..<weekGoals.count {
                let goalType = weekGoals[i].targetType
                let value: Double
                
                switch goalType {
                case .distance:
                    value = (session.totalDistanceMeters ?? 0)
                case .duration:
                    value = (session.durationSeconds ?? 0)
                }
                
                // Ajouter la contribution
                if weekGoals[i].addContribution(sessionId: sessionId, value: value) {
                    updated = true
                    Logger.log("✅ Objectif \(goalType.rawValue) mis à jour: +\(String(format: "%.1f", value))", category: .service)
                }
            }
            
            if updated {
                // Initialiser weeklyGoals si nil
                if user.weeklyGoals == nil {
                    user.weeklyGoals = []
                }
                
                // Mettre à jour les objectifs dans le tableau complet
                for goal in weekGoals {
                    if let index = user.weeklyGoals?.firstIndex(where: { $0.id == goal.id }) {
                        user.weeklyGoals?[index] = goal
                    }
                }
                
                // Sauvegarder dans Firestore
                try db.collection("users").document(userId).setData(from: user, merge: true)
                
                // Mettre à jour le cache local
                await MainActor.run {
                    self.currentWeekGoals = weekGoals
                }
                
                // Recalculer la consistance
                _ = try await calculateConsistencyRate(for: userId)
                
                Logger.logSuccess("✅ Objectifs hebdo mis à jour", category: .service)
            }
            
        } catch {
            Logger.logError(error, context: "updateWeeklyGoals", category: .service)
            throw ProgressionError.updateFailed(error)
        }
    }
    
    /// Crée un nouvel objectif hebdomadaire
    ///
    /// - Parameters:
    ///   - userId: ID de l'utilisateur
    ///   - type: Distance ou Durée
    ///   - value: Valeur cible (en mètres ou secondes selon le type)
    /// - Throws: `ProgressionError` si création échoue
    func createWeeklyGoal(for userId: String, type: GoalType, value: Double) async throws {
        Logger.log("📊 Création objectif: \(type.rawValue) = \(value)", category: .service)
        
        guard value > 0 else {
            throw ProgressionError.invalidGoalValue
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Récupérer l'utilisateur
            let userDoc = try await db.collection("users").document(userId).getDocument()
            var user = try userDoc.data(as: UserModel.self)
            
            // Créer le nouvel objectif
            let startOfWeek = Calendar.current.startOfWeek(for: Date())
            let newGoal = WeeklyGoal(
                weekStartDate: startOfWeek,
                targetType: type,
                targetValue: value
            )
            
            // Vérifier qu'il n'existe pas déjà un objectif du même type cette semaine
            let existingGoal = (user.weeklyGoals ?? []).first {
                $0.targetType == type &&
                Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .weekOfYear)
            }
            
            if existingGoal != nil {
                throw ProgressionError.goalAlreadyExists
            }
            
            // Initialiser weeklyGoals si nil
            if user.weeklyGoals == nil {
                user.weeklyGoals = []
            }
            
            // Ajouter à la liste
            user.weeklyGoals?.append(newGoal)
            
            // Nettoyer les objectifs de plus de 12 semaines
            let twelveWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -12, to: Date()) ?? Date()
            user.weeklyGoals = user.weeklyGoals?.filter { $0.weekStartDate >= twelveWeeksAgo }
            
            // Sauvegarder
            try db.collection("users").document(userId).setData(from: user, merge: true)
            
            // Mettre à jour le cache local
            await MainActor.run {
                self.currentWeekGoals.append(newGoal)
            }
            
            Logger.logSuccess("✅ Objectif créé: \(type.displayName) \(newGoal.formattedTarget)", category: .service)
            
        } catch {
            Logger.logError(error, context: "createWeeklyGoal", category: .service)
            throw ProgressionError.creationFailed(error)
        }
    }
    
    /// Charge les objectifs de la semaine en cours
    ///
    /// - Parameter userId: ID de l'utilisateur
    /// - Throws: `ProgressionError` si chargement échoue
    func loadCurrentWeekGoals(for userId: String) async throws {
        Logger.log("📊 Chargement objectifs semaine en cours", category: .service)
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            let user = try userDoc.data(as: UserModel.self)
            
            let startOfWeek = Calendar.current.startOfWeek(for: Date())
            let goals = (user.weeklyGoals ?? []).filter {
                Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .weekOfYear)
            }
            
            await MainActor.run {
                self.currentWeekGoals = goals
                self.consistencyRate = user.consistencyRate ?? 0.0
            }
            
            Logger.logSuccess("✅ \(goals.count) objectif(s) chargé(s)", category: .service)
            
        } catch {
            Logger.logError(error, context: "loadCurrentWeekGoals", category: .service)
            throw ProgressionError.loadFailed(error)
        }
    }
    
    /// Récupère la couleur de la barre de progression
    ///
    /// - Vert : ≥ 75%
    /// - Jaune : 50-74%
    /// - Rouge : < 50%
    ///
    /// - Parameter rate: Taux de consistance (0.0 - 1.0), peut être nil
    /// - Returns: Couleur de progression
    func getProgressionColor(for rate: Double? = nil) -> ProgressionColor {
        let safeRate = rate ?? self.consistencyRate
        
        switch safeRate {
        case 0.75...1.0:
            return .excellent
        case 0.5..<0.75:
            return .warning
        default:
            return .critical
        }
    }
}

// MARK: - Errors

/// Erreurs du service de progression
enum ProgressionError: LocalizedError {
    case userNotFound
    case invalidSession
    case invalidGoalValue
    case goalAlreadyExists
    case calculationFailed(Error)
    case updateFailed(Error)
    case creationFailed(Error)
    case loadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Utilisateur introuvable"
        case .invalidSession:
            return "Session invalide"
        case .invalidGoalValue:
            return "Valeur d'objectif invalide (doit être > 0)"
        case .goalAlreadyExists:
            return "Un objectif de ce type existe déjà cette semaine"
        case .calculationFailed(let error):
            return "Échec du calcul de consistance : \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Échec de mise à jour : \(error.localizedDescription)"
        case .creationFailed(let error):
            return "Échec de création : \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Échec de chargement : \(error.localizedDescription)"
        }
    }
}
