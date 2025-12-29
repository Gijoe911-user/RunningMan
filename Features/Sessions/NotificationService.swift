//
//  NotificationService.swift
//  RunningMan
//
//  Service centralisé pour la gestion des notifications
//

import Foundation
import UserNotifications

/// Service responsable de la gestion des notifications locales et push
///
/// Ce service centralise toutes les demandes de notifications de l'app.
/// Aucune View ni ViewModel ne doit appeler directement `UNUserNotificationCenter`.
///
/// **Responsabilités :**
/// - Demander les autorisations
/// - Envoyer des notifications locales
/// - Gérer les actions utilisateur sur les notifications
///
/// **Usage :**
/// ```swift
/// // Dans un ViewModel
/// NotificationService.shared.notifyRunnerStarted(runnerName: "Alice")
/// ```
final class NotificationService: NSObject {
    
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        Logger.log("NotificationService initialisé", category: .general)
    }
    
    // MARK: - Permissions
    
    /// Demande l'autorisation d'envoyer des notifications à l'utilisateur
    ///
    /// Doit être appelé au démarrage de l'app ou avant d'envoyer la première notification.
    ///
    /// - Returns: `true` si l'utilisateur a accepté
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        let granted = try await center.requestAuthorization(options: options)
        
        Logger.log(
            granted ? "✅ Notifications autorisées" : "❌ Notifications refusées",
            category: .general
        )
        
        return granted
    }
    
    // MARK: - Squad Notifications
    
    /// Notifie quand un membre de la squad démarre une session
    /// - Parameters:
    ///   - runnerName: Nom du coureur qui démarre
    ///   - squadName: Nom de la squad (optionnel)
    func notifyRunnerStarted(runnerName: String, squadName: String? = nil) {
        guard FeatureFlags.liveNotifications else {
            Logger.log("⚠️ Live notifications désactivées (Feature Flag)", category: .general)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Live Run ! 🏃‍♂️"
        
        if let squad = squadName {
            content.body = "\(runnerName) vient de commencer une session dans \(squad). Rejoins-le ou encourage-le !"
        } else {
            content.body = "\(runnerName) vient de commencer une session. Rejoins-le ou encourage-le !"
        }
        
        content.sound = .default
        content.categoryIdentifier = "RUN_STARTED"
        
        sendLocalNotification(content: content, id: "run_started_\(UUID().uuidString)")
    }
    
    /// Notifie quand une session est sur le point de commencer
    /// - Parameters:
    ///   - sessionTitle: Titre de la session
    ///   - startTime: Heure de début
    func notifySessionStartingSoon(sessionTitle: String, startTime: Date) {
        guard FeatureFlags.liveNotifications else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Session à venir"
        content.body = "\(sessionTitle) commence dans 15 minutes !"
        content.sound = .default
        
        // Trigger 15 minutes avant
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: startTime)!
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "session_reminder_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                Logger.logError(error, context: "Planification notification session")
            }
        }
    }
    
    // MARK: - Message Notifications
    
    /// Notifie l'utilisateur d'un nouveau message dans la squad
    /// - Parameters:
    ///   - sender: Nom de l'expéditeur
    ///   - text: Contenu du message
    ///   - squadName: Nom de la squad
    func notifyNewMessage(from sender: String, text: String, squadName: String) {
        guard FeatureFlags.textMessaging else {
            Logger.log("⚠️ Text messaging désactivé (Feature Flag)", category: .general)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Message de \(sender)"
        content.body = text
        content.sound = .default
        content.categoryIdentifier = "MESSAGE"
        content.userInfo = ["squadName": squadName, "sender": sender]
        
        sendLocalNotification(content: content, id: "msg_\(UUID().uuidString)")
    }
    
    // MARK: - Achievement Notifications
    
    /// Notifie l'utilisateur d'un objectif atteint
    /// - Parameters:
    ///   - achievement: Description de l'achievement
    ///   - icon: Emoji ou icône SF Symbol
    func notifyAchievementUnlocked(achievement: String, icon: String = "🏆") {
        let content = UNMutableNotificationContent()
        content.title = "\(icon) Objectif atteint !"
        content.body = achievement
        content.sound = .default
        
        sendLocalNotification(content: content, id: "achievement_\(UUID().uuidString)")
    }
    
    // MARK: - Marathon Notifications
    
    /// Notifie l'utilisateur d'un jalon dans sa préparation marathon
    /// - Parameters:
    ///   - milestone: Description du jalon (ex: "10 km parcourus cette semaine")
    ///   - daysRemaining: Jours restants avant le marathon
    func notifyMarathonMilestone(milestone: String, daysRemaining: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Préparation Marathon"
        content.body = "\(milestone) - Plus que \(daysRemaining) jours !"
        content.sound = .default
        
        sendLocalNotification(content: content, id: "marathon_\(UUID().uuidString)")
    }
    
    // MARK: - Private Helpers
    
    /// Envoie une notification locale immédiate
    /// - Parameters:
    ///   - content: Contenu de la notification
    ///   - id: Identifiant unique
    private func sendLocalNotification(content: UNMutableNotificationContent, id: String) {
        // trigger = nil signifie "immédiat"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        
        center.add(request) { error in
            if let error = error {
                Logger.logError(error, context: "Envoi notification locale")
            } else {
                Logger.log("📬 Notification envoyée: \(content.title)", category: .general)
            }
        }
    }
    
    // MARK: - Badge Management
    
    /// Met à jour le badge de l'app (nombre de notifications non lues)
    /// - Parameter count: Nombre à afficher sur l'icône
    func updateBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                Logger.logError(error, context: "Mise à jour badge")
            }
        }
    }
    
    /// Réinitialise le badge à zéro
    func clearBadge() {
        updateBadge(count: 0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    /// Gère l'affichage des notifications même quand l'app est au premier plan
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Afficher banner + son + badge même si l'app est ouverte
        completionHandler([.banner, .sound, .list])
    }
    
    /// Gère l'action quand l'utilisateur clique sur une notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let categoryId = response.notification.request.content.categoryIdentifier
        
        Logger.log("📬 Notification cliquée: \(categoryId)", category: .general)
        
        // TODO: Implémenter le deep-linking
        // Exemples :
        // - RUN_STARTED → Ouvrir la session active
        // - MESSAGE → Ouvrir le chat de la squad
        // - ACHIEVEMENT → Ouvrir la page des achievements
        
        switch categoryId {
        case "RUN_STARTED":
            Logger.log("🏃 TODO: Ouvrir la session active", category: .general)
        case "MESSAGE":
            if let squadName = userInfo["squadName"] as? String {
                Logger.log("💬 TODO: Ouvrir le chat de \(squadName)", category: .general)
            }
        default:
            break
        }
        
        completionHandler()
    }
}
