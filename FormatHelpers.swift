//
//  FormatHelpers.swift
//  RunningMan
//
//  Extensions centralisées pour le formatage
//  ✅ DRY : Don't Repeat Yourself - Toutes les fonctions de formatage sont ici
//

import Foundation

// MARK: - TimeInterval Formatting Extensions

extension TimeInterval {
    
    /// Formate une durée en heures:minutes:secondes (ex: "01:23:45" ou "23:45")
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Formate une durée en texte (ex: "45 min", "1h 23min")
    var formattedDurationText: String {
        let minutes = Int(self) / 60
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)min"
        }
    }
    
    /// Formate une durée pour l'affichage compact (ex: "45m", "1h23")
    var formattedDurationCompact: String {
        let minutes = Int(self) / 60
        
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h\(mins)" : "\(hours)h"
        }
    }
}

// MARK: - Double Distance Formatting Extensions

extension Double {
    
    /// Formate une distance en mètres vers kilomètres (ex: "12.5 km")
    var formattedDistanceKm: String {
        String(format: "%.2f km", self / 1000.0)
    }
    
    /// Formate une distance avec précision personnalisée
    func formattedDistance(precision: Int = 2) -> String {
        String(format: "%.\(precision)f km", self / 1000.0)
    }
    
    /// Formate une vitesse en m/s vers km/h (ex: "12.5 km/h")
    var formattedSpeedKmh: String {
        String(format: "%.1f km/h", self * 3.6)
    }
    
    /// Formate une allure (pace) en min/km (ex: "5:30 /km")
    var formattedPaceMinKm: String {
        guard self > 0 else { return "--:-- /km" }
        
        let minutesPerKm = (1000.0 / self) / 60.0
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    /// Formate un pourcentage (ex: "85%")
    var formattedPercentage: String {
        String(format: "%.0f%%", self * 100)
    }
}

// MARK: - Date Formatting Extensions

extension Date {
    
    /// Formate en date courte (ex: "31 déc.")
    var formattedShortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
    
    /// Formate en date et heure (ex: "31 déc. 14:30")
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
    
    /// Formate en heure uniquement (ex: "14:30")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
    
    /// Formate de manière relative (ex: "Il y a 5 min", "Hier à 14:30")
    var formattedRelative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Durée depuis maintenant en secondes
    var timeIntervalSinceNow: TimeInterval {
        Date().timeIntervalSince(self)
    }
}

// MARK: - Int Formatting Extensions

extension Int {
    
    /// Formate avec séparateurs de milliers (ex: "1 234")
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// Formate en version abrégée (ex: "1.2k", "5.6M")
    var formattedCompact: String {
        switch self {
        case 0..<1000:
            return "\(self)"
        case 1000..<1_000_000:
            let k = Double(self) / 1000.0
            return String(format: "%.1fk", k)
        default:
            let m = Double(self) / 1_000_000.0
            return String(format: "%.1fM", m)
        }
    }
}

// MARK: - ViewModel Helper Methods (à utiliser dans les ViewModels)

struct FormatHelper {
    
    /// Formate une distance en mètres
    static func formattedDistance(_ meters: Double) -> String {
        meters.formattedDistanceKm
    }
    
    /// Formate une durée en secondes
    static func formattedDuration(_ seconds: TimeInterval) -> String {
        seconds.formattedDuration
    }
    
    /// Formate une vitesse en m/s
    static func formattedSpeed(_ metersPerSecond: Double) -> String {
        metersPerSecond.formattedSpeedKmh
    }
    
    /// Formate une allure en m/s vers min/km
    static func formattedPace(_ metersPerSecond: Double) -> String {
        metersPerSecond.formattedPaceMinKm
    }
    
    /// Formate une date
    static func formattedDate(_ date: Date) -> String {
        date.formattedShortDate
    }
    
    /// Formate une date et heure
    static func formattedDateTime(_ date: Date) -> String {
        date.formattedDateTime
    }
}

// MARK: - SessionModel Formatting Extensions

extension SessionModel {
    
    /// Distance formatée de la session
    var formattedDistance: String {
        let distance: Double = totalDistanceMeters ?? 0
        return distance.formattedDistanceKm
    }
    
    /// Durée formatée de la session
    var formattedSessionDuration: String {
        let duration: TimeInterval = durationSeconds ?? 0
        return duration.formattedDuration
    }
    
    /// Vitesse moyenne formatée
    var formattedAverageSpeed: String {
        let speed: Double = averageSpeed ?? 0
        return speed.formattedSpeedKmh
    }
    
    /// Allure moyenne formatée
    var formattedAveragePace: String {
        let speed: Double = averageSpeed ?? 0
        return speed.formattedPaceMinKm
    }
    
    /// Date de début formatée
    var formattedStartDate: String {
        startedAt.formattedDateTime
    }
    
    // Note: formattedDurationSinceStart est déjà défini dans SessionModels+Extensions.swift
}
