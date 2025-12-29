//
//  HealthKitManager.swift
//  RunningMan
//
//  Manager pour intégrer HealthKit et collecter les données biométriques
//

import Foundation
import HealthKit
import Combine

/// Manager principal pour HealthKit
@MainActor
class HealthKitManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = HealthKitManager()
    
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var currentHeartRate: Double?
    @Published var currentDistance: Double?
    @Published var currentCalories: Double?
    
    // Queries actives
    private var heartRateQuery: HKAnchoredObjectQuery?  // ✅ Correction du type
    private var workoutSession: HKWorkoutSession?
    
    // Session tracking
    private var activeSessionId: String?
    private var sessionStartTime: Date?
    
    // Stats cumulatives pour la session
    private var heartRateSamples: [Double] = []
    
    // MARK: - Initialization
    private init() {
        checkAvailability()
    }
    
    // MARK: - Availability
    
    /// Vérifie si HealthKit est disponible sur cet appareil
    func checkAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.log("⚠️ HealthKit n'est pas disponible sur cet appareil", category: .general)
            return
        }
        Logger.log("✅ HealthKit disponible", category: .general)
    }
    
    // MARK: - Authorization
    
    /// Demande les permissions HealthKit
    func requestAuthorization() async throws {
        Logger.log("🔐 Demande des permissions HealthKit...", category: .general)
        
        // Types de données à lire
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        // Types de données à écrire (pour créer des workouts)
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            
            await MainActor.run {
                self.isAuthorized = true
            }
            
            Logger.logSuccess("✅ Permissions HealthKit accordées", category: .general)
        } catch {
            Logger.logError(error, context: "requestAuthorization", category: .general)
            throw error
        }
    }
    
    // MARK: - Heart Rate Monitoring
    
    /// Démarre l'observation de la fréquence cardiaque pour une session
    func startHeartRateQuery(sessionId: String) {
        Logger.log("❤️ Démarrage de l'observation de la fréquence cardiaque", category: .general)
        
        guard isAuthorized else {
            Logger.log("⚠️ HealthKit non autorisé", category: .general)
            return
        }
        
        activeSessionId = sessionId
        sessionStartTime = Date()
        heartRateSamples.removeAll()
        
        // Type de données : fréquence cardiaque
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            Logger.log("❌ Impossible de récupérer le type de fréquence cardiaque", category: .general)
            return
        }
        
        // Créer une query d'ancrage pour observer les nouvelles données en temps réel
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    Logger.logError(error, context: "heartRateQuery", category: .general)
                }
                return
            }
            
            Task { @MainActor in
                await self.processHeartRateSamples(samples)
            }
        }
        
        // Handler pour les mises à jour continues
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    Logger.logError(error, context: "heartRateQuery.updateHandler", category: .general)
                }
                return
            }
            
            Task { @MainActor in
                await self.processHeartRateSamples(samples)
            }
        }
        
        heartRateQuery = query
        healthStore.execute(query)
        
        Logger.logSuccess("✅ Observation de la fréquence cardiaque démarrée", category: .general)
    }
    
    /// Arrête l'observation de la fréquence cardiaque
    func stopHeartRateQuery() {
        Logger.log("🛑 Arrêt de l'observation de la fréquence cardiaque", category: .general)
        
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        
        activeSessionId = nil
        sessionStartTime = nil
        heartRateSamples.removeAll()
        
        Task { @MainActor in
            self.currentHeartRate = nil
        }
    }
    
    // MARK: - Process Heart Rate Samples
    
    /// Traite les nouveaux échantillons de fréquence cardiaque
    private func processHeartRateSamples(_ samples: [HKSample]?) async {
        guard let samples = samples as? [HKQuantitySample],
              let sessionId = activeSessionId,
              let userId = AuthService.shared.currentUserId else {
            return
        }
        
        for sample in samples {
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            
            // Mettre à jour le BPM actuel
            self.currentHeartRate = heartRate
            
            // Ajouter aux échantillons pour calculer la moyenne
            heartRateSamples.append(heartRate)
            
            // Calculer les stats
            let averageHeartRate = heartRateSamples.reduce(0, +) / Double(heartRateSamples.count)
            let maxHeartRate = heartRateSamples.max() ?? heartRate
            let minHeartRate = heartRateSamples.min() ?? heartRate
            
            Logger.log("❤️ BPM: \(Int(heartRate)) (moy: \(Int(averageHeartRate)), max: \(Int(maxHeartRate)))", category: .general)
            
            // Mettre à jour Firestore via SessionService
            Task {
                do {
                    try await SessionService.shared.updateParticipantLiveStats(
                        sessionId: sessionId,
                        userId: userId,
                        stats: ParticipantStats(
                            userId: userId,
                            currentHeartRate: heartRate,
                            averageHeartRate: averageHeartRate,
                            maxHeartRate: maxHeartRate,
                            minHeartRate: minHeartRate,
                            heartRateUpdatedAt: Date()
                        )
                    )
                } catch {
                    Logger.logError(error, context: "updateParticipantLiveStats", category: .general)
                }
            }
        }
    }
    
    // MARK: - Distance Monitoring
    
    /// Récupère la distance parcourue depuis le début de la session
    func queryDistance(since startDate: Date) async throws -> Double {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.unavailableType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { query, statistics, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let statistics = statistics,
                      let sum = statistics.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let distanceMeters = sum.doubleValue(for: .meter())
                continuation.resume(returning: distanceMeters)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Calories Monitoring
    
    /// Récupère les calories brûlées depuis le début de la session
    func queryCalories(since startDate: Date) async throws -> Double {
        guard let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.unavailableType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { query, statistics, error in
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let statistics = statistics,
                      let sum = statistics.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let calories = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Periodic Stats Update
    
    /// Démarre la mise à jour périodique des stats (distance, calories)
    func startPeriodicStatsUpdate(sessionId: String) {
        Logger.log("🔄 Démarrage de la mise à jour périodique des stats", category: .general)
        
        guard let startTime = sessionStartTime else { return }
        
        Task {
            while activeSessionId == sessionId {
                // Attendre 10 secondes entre chaque mise à jour
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                
                guard activeSessionId == sessionId else { break }
                
                // Récupérer distance et calories
                do {
                    let distance = try await queryDistance(since: startTime)
                    let calories = try await queryCalories(since: startTime)
                    
                    await MainActor.run {
                        self.currentDistance = distance
                        self.currentCalories = calories
                    }
                    
                    Logger.log("📊 Stats HealthKit: \(Int(distance))m, \(Int(calories)) kcal", category: .general)
                    
                    // Optionnel : mettre à jour Firestore avec distance et calories
                    if let userId = AuthService.shared.currentUserId {
                        try await SessionService.shared.updateParticipantLiveStats(
                            sessionId: sessionId,
                            userId: userId,
                            stats: ParticipantStats(
                                userId: userId,
                                distance: distance,
                                calories: calories
                            )
                        )
                    }
                } catch {
                    Logger.logError(error, context: "periodicStatsUpdate", category: .general)
                }
            }
        }
    }
    
    // MARK: - Workout Session (Bonus)
    
    /// Démarre une session d'entraînement HealthKit (pour Apple Watch)
    func startWorkoutSession(activityType: HKWorkoutActivityType = .running) throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .outdoor
        
        let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        self.workoutSession = session
        
        session.startActivity(with: Date())
        
        Logger.logSuccess("✅ Workout session démarrée", category: .general)
    }
    
    /// Arrête la session d'entraînement HealthKit
    func stopWorkoutSession() {
        workoutSession?.end()
        workoutSession = nil
        
        Logger.log("🛑 Workout session terminée", category: .general)
    }
}

// MARK: - Errors

enum HealthKitError: Error, LocalizedError {
    case unavailable
    case unavailableType
    case unauthorized
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "HealthKit n'est pas disponible sur cet appareil"
        case .unavailableType:
            return "Type de données HealthKit non disponible"
        case .unauthorized:
            return "Permissions HealthKit non accordées"
        case .queryFailed:
            return "Échec de la requête HealthKit"
        }
    }
}
