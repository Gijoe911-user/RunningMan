//
//  OnboardingContent.swift
//  RunningMan
//
//  Contenu paramétrable pour l'onboarding et l'aide
//

import Foundation

/// Modèle pour une étape d'onboarding
struct OnboardingStep: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let description: String
    let icon: String
    let color: String  // Nom de la couleur (ex: "coralAccent")
    let detailedExplanation: String
    
    /// Texte complet pour la lecture vocale
    var speechText: String {
        "Étape \(number): \(title). \(description). \(detailedExplanation)"
    }
}

/// Configuration complète de l'onboarding
struct OnboardingConfiguration {
    let welcomeTitle: String
    let welcomeSubtitle: String
    let steps: [OnboardingStep]
    
    /// Texte complet pour la lecture vocale
    var fullSpeechText: String {
        var text = "\(welcomeTitle). \(welcomeSubtitle). "
        text += steps.map { $0.speechText }.joined(separator: ". ")
        return text
    }
    
    /// Configuration par défaut
    static let `default` = OnboardingConfiguration(
        welcomeTitle: "Bienvenue sur RunningMan",
        welcomeSubtitle: "Votre application pour courir ensemble, partout et tout le temps",
        steps: [
            OnboardingStep(
                number: 1,
                title: "Créez votre Squad",
                description: "Une Squad, c'est votre groupe d'amis coureurs",
                icon: "person.3.fill",
                color: "coralAccent",
                detailedExplanation: """
                Commencez par créer votre Squad et invitez vos amis en partageant le code d'invitation. \
                Une Squad est un groupe privé où vous pourrez organiser des sessions de course ensemble. \
                Vous pouvez appartenir à plusieurs Squads : une pour vos amis proches, une pour votre club, \
                une pour vos collègues de travail.
                """
            ),
            
            OnboardingStep(
                number: 2,
                title: "Lancez ou rejoignez des Sessions",
                description: "Organisez des séances d'entraînement planifiées ou spontanées",
                icon: "calendar.badge.plus",
                color: "pinkAccent",
                detailedExplanation: """
                Au sein de votre Squad, vous pouvez lancer ou rejoindre des sessions de course. \
                Deux types de sessions sont disponibles : les sessions planifiées, que vous programmez à l'avance \
                avec date et heure, et les sessions live, que vous lancez immédiatement. \
                Tous les membres de la Squad peuvent voir les sessions actives et les rejoindre en temps réel.
                """
            ),
            
            OnboardingStep(
                number: 3,
                title: "Trackez vos activités",
                description: "Partagez votre position et suivez vos performances",
                icon: "location.fill.viewfinder",
                color: "blueAccent",
                detailedExplanation: """
                Dans l'onglet Sessions, vous verrez toutes les sessions de vos Squads prévues ou lancées. \
                Vous pouvez rejoindre une session pour voir la carte en temps réel et la position de vos amis, \
                ou démarrer le tracker d'activité pour enregistrer votre course avec GPS, distance, vitesse, \
                et données HealthKit. Vos amis peuvent vous suivre en direct sur la carte.
                """
            ),
            
            OnboardingStep(
                number: 4,
                title: "Partagez avec vos amis",
                description: "Messages vocaux et texte pendant vos courses",
                icon: "message.fill",
                color: "greenAccent",
                detailedExplanation: """
                Le centre de notifications vous permet de partager des messages vocaux ou texte avec votre Squad, \
                avec les participants d'une session active, ou avec un coureur spécifique. \
                Les messages sont envoyés immédiatement et, si un coureur a lancé son tracking, \
                ils sont lus automatiquement sauf s'il a choisi de rester dans sa bulle en course dans son profil. \
                Trois modes de partage sont disponibles : Toute ma Squad, Ma session active, ou Un seul participant.
                """
            )
        ]
    )
}
