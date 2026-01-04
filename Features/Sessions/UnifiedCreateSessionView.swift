//
//  UnifiedCreateSessionView.swift
//  RunningMan
//
//  Vue unifiée pour créer une session avec tous les paramètres
//  - Type: Entraînement / Course
//  - Rôle: Coureur / Supporter
//  - Objectifs: Distance et/ou durée
//  - Options avancées: Lieu de RDV, etc.
//

import SwiftUI
import MapKit
import FirebaseFirestore

/// Vue complète et unifiée pour créer une session
///
/// **Fonctionnalités :**
/// - Choix du type (Entraînement / Course)
/// - Choix du rôle (Coureur / Supporter)
/// - Définir distance et durée cibles
/// - Ajouter un lieu de rendez-vous
/// - Inviter les participants
/// - Lancer immédiatement ou planifier
///
/// **Principe DRY :**
/// - Remplace tous les points d'entrée de création de session
/// - Une seule source de vérité pour les paramètres
/// - Validations centralisées
struct UnifiedCreateSessionView: View {
    
    // MARK: - Properties
    
    let squad: SquadModel
    let onSessionCreated: ((SessionModel) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionType: SessionType = .training
    @State private var userRole: UserRole = .runner
    @State private var targetDistance: String = ""
    @State private var useQuickDistance: Bool = true
    @State private var quickDistance: Double = 5.0
    @State private var targetDuration: String = ""
    @State private var sessionTitle: String = ""
    @State private var sessionNotes: String = ""
    @State private var hasRDVLocation: Bool = false
    @State private var rdvLocationName: String = ""
    @State private var rdvCoordinate: CLLocationCoordinate2D?
    @State private var startNow: Bool = true
    @State private var scheduledDate: Date = Date().addingTimeInterval(3600) // +1h par défaut
    
    @State private var isCreating: Bool = false
    @State private var errorMessage: String?
    @State private var showLocationPicker: Bool = false
    
    @State private var currentStep: CreationStep = .basics
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                    
                    // Content selon l'étape
                    TabView(selection: $currentStep) {
                        // Étape 1 : Type et rôle
                        basicsStep
                            .tag(CreationStep.basics)
                        
                        // Étape 2 : Objectifs
                        goalsStep
                            .tag(CreationStep.goals)
                        
                        // Étape 3 : Options
                        optionsStep
                            .tag(CreationStep.options)
                        
                        // Étape 4 : Récapitulatif
                        summaryStep
                            .tag(CreationStep.summary)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Boutons navigation
                    navigationButtons
                }
            }
            .navigationTitle("Nouvelle session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(CreationStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.coralAccent : Color.white.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Step 1: Basics
    
    private var basicsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header - Type de session
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.coralAccent.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.run")
                            .font(.headline)
                            .foregroundColor(.coralAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type de session")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Choisissez le type d'activité")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Type de session
                VStack(spacing: 12) {
                    SessionTypeButton(
                        type: .training,
                        isSelected: sessionType == .training
                    ) {
                        sessionType = .training
                    }
                    
                    SessionTypeButton(
                        type: .race,
                        isSelected: sessionType == .race
                    ) {
                        sessionType = .race
                    }
                }
                
                Divider()
                    .background(.white.opacity(0.2))
                    .padding(.vertical)
                
                // Header - Votre rôle
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.coralAccent.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.fill")
                            .font(.headline)
                            .foregroundColor(.coralAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Votre rôle")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Comment participez-vous ?")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 12) {
                    RoleButton(
                        role: .runner,
                        isSelected: userRole == .runner
                    ) {
                        userRole = .runner
                    }
                    
                    RoleButton(
                        role: .supporter,
                        isSelected: userRole == .supporter
                    ) {
                        userRole = .supporter
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Step 2: Goals
    
    private var goalsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header - Objectifs
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.coralAccent.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "target")
                            .font(.headline)
                            .foregroundColor(.coralAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Objectifs")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Fixez vos objectifs pour la session")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Distance
                VStack(alignment: .leading, spacing: 12) {
                    Text("Distance cible")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Toggle("", isOn: $useQuickDistance)
                            .labelsHidden()
                        
                        Text(useQuickDistance ? "Sélection rapide" : "Personnalisée")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if useQuickDistance {
                        Picker("Distance", selection: $quickDistance) {
                            Text("1 km").tag(1.0)
                            Text("3 km").tag(3.0)
                            Text("5 km").tag(5.0)
                            Text("10 km").tag(10.0)
                            Text("15 km").tag(15.0)
                            Text("21 km (Semi)").tag(21.1)
                            Text("42 km (Marathon)").tag(42.2)
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        HStack {
                            TextField("Ex: 10", text: $targetDistance)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundColor(.white)
                            
                            Text("km")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 40)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Durée
                VStack(alignment: .leading, spacing: 12) {
                    Text("Durée cible (optionnel)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("Ex: 60", text: $targetDuration)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(.white)
                        
                        Text("min")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
    }
    
    // MARK: - Step 3: Options
    
    private var optionsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header - Options
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.coralAccent.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "gear")
                            .font(.headline)
                            .foregroundColor(.coralAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Options")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Personnalisez votre session")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Titre
                VStack(alignment: .leading, spacing: 8) {
                    Text("Titre (optionnel)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Ex: Course du dimanche", text: $sessionTitle)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                }
                
                // Lieu de RDV
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $hasRDVLocation) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Définir un lieu de rendez-vous")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Les participants sauront où se retrouver")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .tint(.coralAccent)
                    
                    if hasRDVLocation {
                        VStack(spacing: 12) {
                            TextField("Nom du lieu", text: $rdvLocationName)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundColor(.white)
                            
                            Button {
                                showLocationPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text(rdvCoordinate != nil ? "Changer de lieu" : "Choisir sur la carte")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Planification
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $startNow) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Démarrer immédiatement")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Ou planifier pour plus tard")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .tint(.coralAccent)
                    
                    if !startNow {
                        DatePicker(
                            "Date et heure",
                            selection: $scheduledDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .tint(.coralAccent)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (optionnel)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $sessionNotes)
                        .frame(height: 100)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                selectedLocation: $rdvLocationName,
                selectedCoordinate: $rdvCoordinate
            )
        }
    }
    
    // MARK: - Step 4: Summary
    
    private var summaryStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header - Récapitulatif
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.coralAccent.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.coralAccent)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Récapitulatif")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Vérifiez les détails avant de créer")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Type et rôle
                SummarySection(title: "Session") {
                    SummaryRow(label: "Type", value: sessionType.displayName, icon: sessionType.icon)
                    SummaryRow(label: "Votre rôle", value: userRole.displayName, icon: userRole.icon)
                    SummaryRow(label: "Squad", value: squad.name, icon: "person.3.fill")
                }
                
                // Objectifs
                if hasGoals {
                    SummarySection(title: "Objectifs") {
                        if let distance = finalDistance {
                            SummaryRow(label: "Distance", value: String(format: "%.1f km", distance), icon: "location.fill")
                        }
                        if let duration = finalDuration {
                            SummaryRow(label: "Durée", value: "\(duration) min", icon: "clock.fill")
                        }
                    }
                }
                
                // Options
                SummarySection(title: "Options") {
                    if !sessionTitle.isEmpty {
                        SummaryRow(label: "Titre", value: sessionTitle, icon: "text.quote")
                    }
                    
                    if hasRDVLocation && !rdvLocationName.isEmpty {
                        SummaryRow(label: "Lieu de RDV", value: rdvLocationName, icon: "map.fill")
                    }
                    
                    SummaryRow(
                        label: "Démarrage",
                        value: startNow ? "Immédiat" : formatDate(scheduledDate),
                        icon: "calendar"
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .basics {
                Button {
                    withAnimation {
                        currentStep = CreationStep(rawValue: currentStep.rawValue - 1) ?? .basics
                    }
                } label: {
                    Label("Précédent", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                }
            }
            
            Button {
                if currentStep == .summary {
                    createSession()
                } else {
                    withAnimation {
                        currentStep = CreationStep(rawValue: currentStep.rawValue + 1) ?? .summary
                    }
                }
            } label: {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label(
                        currentStep == .summary ? "Créer" : "Suivant",
                        systemImage: currentStep == .summary ? "checkmark" : "chevron.right"
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.coralAccent, .pinkAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.white)
            .disabled(isCreating || !canProceed)
        }
        .padding()
    }
    
    // MARK: - Create Session
    
    private func createSession() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                guard let userId = AuthService.shared.currentUserId else {
                    errorMessage = "Utilisateur non connecté"
                    isCreating = false
                    return
                }
                
                // Créer la session avec tous les paramètres
                let session = try await SessionService.shared.createSession(
                    squadId: squad.id!,
                    creatorId: userId,
                    startLocation: nil  // TODO: Ajouter la position actuelle si dispo
                )
                
                // Mettre à jour avec les paramètres additionnels
                if let sessionId = session.id {
                    try await updateSessionParameters(sessionId: sessionId)
                }
                
                Logger.logSuccess("✅ Session créée avec succès", category: .session)
                
                await MainActor.run {
                    onSessionCreated?(session)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    Logger.logError(error, context: "createSession", category: .session)
                    errorMessage = "Erreur lors de la création: \(error.localizedDescription)"
                    isCreating = false
                }
            }
        }
    }
    
    private func updateSessionParameters(sessionId: String) async throws {
        var updateData: [String: Any] = [:]
        
        // Titre
        if !sessionTitle.isEmpty {
            updateData["title"] = sessionTitle
        }
        
        // Notes
        if !sessionNotes.isEmpty {
            updateData["notes"] = sessionNotes
        }
        
        // Distance cible
        if let distance = finalDistance {
            updateData["targetDistanceMeters"] = distance * 1000
        }
        
        // Lieu de RDV
        if hasRDVLocation && !rdvLocationName.isEmpty {
            updateData["meetingLocationName"] = rdvLocationName
            if let coordinate = rdvCoordinate {
                updateData["meetingLocationCoordinate"] = GeoPoint(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            }
        }
        
        // Type d'activité
        updateData["activityType"] = sessionType == .training ? ActivityType.training.rawValue : ActivityType.race.rawValue
        
        if !updateData.isEmpty {
            let db = Firestore.firestore()
            try await db.collection("sessions").document(sessionId).updateData(updateData)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canProceed: Bool {
        switch currentStep {
        case .basics:
            return true
        case .goals:
            return hasGoals // Au moins une distance ou durée
        case .options:
            return true
        case .summary:
            return true
        }
    }
    
    private var hasGoals: Bool {
        finalDistance != nil || finalDuration != nil
    }
    
    private var finalDistance: Double? {
        if useQuickDistance {
            return quickDistance
        } else if let value = Double(targetDistance), value > 0 {
            return value
        }
        return nil
    }
    
    private var finalDuration: Int? {
        if let value = Int(targetDuration), value > 0 {
            return value
        }
        return nil
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

enum CreationStep: Int, CaseIterable {
    case basics = 0
    case goals = 1
    case options = 2
    case summary = 3
}

enum SessionType {
    case training
    case race
    
    var displayName: String {
        switch self {
        case .training: return "Entraînement"
        case .race: return "Course"
        }
    }
    
    var icon: String {
        switch self {
        case .training: return "figure.walk"
        case .race: return "figure.run"
        }
    }
    
    var description: String {
        switch self {
        case .training: return "Session détendue sans objectif de temps"
        case .race: return "Compétition avec classement et chrono"
        }
    }
}

enum UserRole {
    case runner
    case supporter
    
    var displayName: String {
        switch self {
        case .runner: return "Coureur"
        case .supporter: return "Supporter"
        }
    }
    
    var icon: String {
        switch self {
        case .runner: return "figure.run"
        case .supporter: return "hand.thumbsup.fill"
        }
    }
    
    var description: String {
        switch self {
        case .runner: return "Je vais courir avec tracking GPS"
        case .supporter: return "Je viens soutenir et encourager"
        }
    }
}

// MARK: - Supporting Views

struct SessionTypeButton: View {
    let type: SessionType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .coralAccent : .white.opacity(0.6))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.coralAccent)
                    .font(.title3)
                }
            }
            .padding()
            .background(
                isSelected
                    ? Color.coralAccent.opacity(0.2)
                    : Color.white.opacity(0.05)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.coralAccent, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct RoleButton: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: role.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blueAccent : .white.opacity(0.6))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(role.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blueAccent)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                isSelected
                    ? Color.blueAccent.opacity(0.2)
                    : Color.white.opacity(0.05)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.blueAccent, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SummarySection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                content
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.coralAccent)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    UnifiedCreateSessionView(
        squad: SquadModel(
            name: "Les Runners",
            description: "Squad test",
            inviteCode: "TEST123",
            creatorId: "user1",
            members: ["user1": .admin]
        ),
        onSessionCreated: { _ in }
    )
    .preferredColorScheme(.dark)
}
