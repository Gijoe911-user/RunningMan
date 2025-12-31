//
//  TrainingProgramModel.swift
//  RunningMan
//
//  Modèle pour les programmes d'entraînement
//

import Foundation
import FirebaseFirestore

// MARK: - Training Program Theme

enum TrainingTheme: String, Codable, CaseIterable {
    case standard = "standard"          // Course standard
    case interval = "interval"          // Fractionné
    case recovery = "recovery"          // Détente/Récupération
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .interval: return "Fractionné"
        case .recovery: return "Détente"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "figure.run"
        case .interval: return "chart.bar.fill"
        case .recovery: return "leaf.fill"
        }
    }
    
    var description: String {
        switch self {
        case .standard:
            return "Course à allure constante"
        case .interval:
            return "Alternance rapide/lent pour progresser"
        case .recovery:
            return "Course tranquille pour récupérer"
        }
    }
}

// MARK: - Training Program Model

struct TrainingProgram: Codable, Identifiable {
    @DocumentID var id: String?
    
    // Métadonnées
    var name: String
    var description: String?
    var createdBy: String  // userId du créateur
    var createdAt: Date
    var updatedAt: Date
    
    // Thème de l'entraînement
    var theme: TrainingTheme
    
    // Objectifs
    var targetDistance: Double?         // en mètres
    var targetDuration: Int?            // en secondes
    var targetPaceMin: Int?             // Allure minimale (sec/km)
    var targetPaceMax: Int?             // Allure maximale (sec/km)
    
    // Paramètres spécifiques au fractionné
    var intervalSegments: [IntervalSegment]?
    
    // Paramètres avancés
    var warmupDuration: Int?            // Échauffement (secondes)
    var cooldownDuration: Int?          // Récupération (secondes)
    var restBetweenIntervals: Int?      // Repos entre séries (secondes)
    
    // Métadonnées d'usage
    var isPublic: Bool = false          // Visible par tous dans la squad
    var usageCount: Int = 0             // Nombre d'utilisations
    var tags: [String] = []             // Tags pour recherche
    
    init(
        name: String,
        createdBy: String,
        theme: TrainingTheme,
        description: String? = nil,
        targetDistance: Double? = nil,
        targetDuration: Int? = nil,
        targetPaceMin: Int? = nil,
        targetPaceMax: Int? = nil,
        intervalSegments: [IntervalSegment]? = nil
    ) {
        self.name = name
        self.createdBy = createdBy
        self.theme = theme
        self.description = description
        self.targetDistance = targetDistance
        self.targetDuration = targetDuration
        self.targetPaceMin = targetPaceMin
        self.targetPaceMax = targetPaceMax
        self.intervalSegments = intervalSegments
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Interval Segment

struct IntervalSegment: Codable, Identifiable {
    var id = UUID()
    var type: IntervalType
    var duration: Int?          // en secondes
    var distance: Double?       // en mètres
    var targetPace: Int?        // sec/km
    var repetitions: Int = 1    // Nombre de répétitions
    
    enum IntervalType: String, Codable {
        case warmup = "warmup"
        case work = "work"          // Effort
        case rest = "rest"          // Récupération
        case cooldown = "cooldown"
        
        var displayName: String {
            switch self {
            case .warmup: return "Échauffement"
            case .work: return "Effort"
            case .rest: return "Récupération"
            case .cooldown: return "Retour au calme"
            }
        }
        
        var color: String {
            switch self {
            case .warmup: return "green"
            case .work: return "red"
            case .rest: return "blue"
            case .cooldown: return "green"
            }
        }
    }
}

// MARK: - Training Program Extensions

extension TrainingProgram {
    
    /// Exporte le programme en JSON
    func exportToJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
    
    /// Importe un programme depuis JSON
    static func importFromJSON(data: Data) throws -> TrainingProgram {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TrainingProgram.self, from: data)
    }
    
    /// Retourne un nom de fichier pour l'export
    var exportFilename: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: createdAt)
        let safeName = name.replacingOccurrences(of: " ", with: "_")
        return "TrainingProgram_\(safeName)_\(dateString).json"
    }
    
    /// Calcule la durée totale estimée
    var estimatedDuration: Int {
        if let duration = targetDuration {
            return duration
        }
        
        // Si fractionné, calculer la somme des segments
        if let segments = intervalSegments {
            return segments.reduce(0) { total, segment in
                let segmentDuration = segment.duration ?? 0
                return total + (segmentDuration * segment.repetitions)
            }
        }
        
        // Si distance et allure sont définies, estimer
        if let distance = targetDistance, let pace = targetPaceMin {
            let distanceKm = distance / 1000.0
            let durationMinutes = distanceKm * Double(pace) / 60.0
            return Int(durationMinutes * 60)
        }
        
        return 0
    }
    
    /// Description courte des objectifs
    var objectiveSummary: String {
        var parts: [String] = []
        
        if let distance = targetDistance {
            parts.append(String(format: "%.1f km", distance / 1000))
        }
        
        if let duration = targetDuration {
            let minutes = duration / 60
            parts.append("\(minutes) min")
        }
        
        if let pace = targetPaceMin {
            let min = pace / 60
            let sec = pace % 60
            parts.append(String(format: "%d:%02d /km", min, sec))
        }
        
        return parts.isEmpty ? "Aucun objectif défini" : parts.joined(separator: " • ")
    }
}

// MARK: - Predefined Templates

extension TrainingProgram {
    
    /// Templates prédéfinis pour démarrage rapide
    static func templates(for userId: String) -> [TrainingProgram] {
        return [
            // 1. Course standard 5km
            TrainingProgram(
                name: "5 km Standard",
                createdBy: userId,
                theme: .standard,
                description: "Course de 5 km à allure régulière",
                targetDistance: 5000,
                targetPaceMin: 300, // 5:00 /km
                targetPaceMax: 360  // 6:00 /km
            ),
            
            // 2. Fractionné 400m x 8
            TrainingProgram(
                name: "8 x 400m",
                createdBy: userId,
                theme: .interval,
                description: "Séance de fractionné court",
                intervalSegments: [
                    IntervalSegment(type: .warmup, duration: 600),  // 10 min échauffement
                    IntervalSegment(type: .work, distance: 400, targetPace: 240, repetitions: 8),  // 8 x 400m rapide
                    IntervalSegment(type: .rest, duration: 90, repetitions: 8),  // 90 sec récup
                    IntervalSegment(type: .cooldown, duration: 600)  // 10 min retour calme
                ]
            ),
            
            // 3. Course de récupération
            TrainingProgram(
                name: "Récupération 30 min",
                createdBy: userId,
                theme: .recovery,
                description: "Course tranquille pour récupérer",
                targetDuration: 1800,  // 30 minutes
                targetPaceMin: 360,    // 6:00 /km minimum
                targetPaceMax: 420     // 7:00 /km maximum
            ),
            
            // 4. Endurance fondamentale
            TrainingProgram(
                name: "10 km Endurance",
                createdBy: userId,
                theme: .standard,
                description: "Développement de l'endurance",
                targetDistance: 10000,
                targetPaceMin: 330,    // 5:30 /km
                targetPaceMax: 390     // 6:30 /km
            )
        ]
    }
}
