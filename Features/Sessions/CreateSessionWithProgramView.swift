//
//  CreateSessionWithProgramView.swift
//  RunningMan
//
//  Vue pour créer une session avec programme d'entraînement et localisation
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct CreateSessionWithProgramView: View {
    let squad: SquadModel
    let onSessionCreated: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    // Étape 1: Informations de base
    @State private var sessionTitle: String = ""
    @State private var activityType: ActivityType = .training
    @State private var selectedTheme: TrainingTheme = .standard
    @State private var isRace: Bool = false  // Session de type course (une seule possible)
    
    // Étape 2: Localisation
    @State private var hasLocation: Bool = false
    @State private var locationName: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showLocationPicker = false
    
    // Étape 3: Programme d'entraînement
    @State private var hasProgram: Bool = false
    @State private var selectedProgram: TrainingProgram?
    @State private var showProgramPicker = false
    @State private var showCreateProgram = false
    
    // Loading & Error
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    // 🏁 Détection de course active
    @State private var activeRaceSession: SessionModel?
    @State private var showJoinRaceDialog = false
    
    // 🚫 Détection de session active du coureur
    @State private var userActiveSession: SessionModel?
    @State private var showUserActiveSessionAlert = false
    
    // Navigation
    @State private var currentStep: CreateSessionStep = .basicInfo
    
    enum CreateSessionStep: Int, CaseIterable {
        case basicInfo = 0
        case location = 1
        case program = 2
        case review = 3
        
        var title: String {
            switch self {
            case .basicInfo: return "Informations"
            case .location: return "Lieu de RDV"
            case .program: return "Programme"
            case .review: return "Récapitulatif"
            }
        }
        
        var icon: String {
            switch self {
            case .basicInfo: return "info.circle.fill"
            case .location: return "mappin.circle.fill"
            case .program: return "doc.text.fill"
            case .review: return "checkmark.circle.fill"
            }
        }
    }
    
    init(squad: SquadModel, onSessionCreated: (() -> Void)? = nil) {
        self.squad = squad
        self.onSessionCreated = onSessionCreated
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .basicInfo:
                                basicInfoStep
                            case .location:
                                locationStep
                            case .program:
                                programStep
                            case .review:
                                reviewStep
                            }
                        }
                        .padding()
                    }
                    
                    // Navigation buttons
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
                    .foregroundColor(.coralAccent)
                    .disabled(isCreating)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    selectedLocation: $locationName,
                    selectedCoordinate: $selectedCoordinate
                )
            }
            .sheet(isPresented: $showProgramPicker) {
                TrainingProgramPickerView(
                    squadId: squad.id ?? "",
                    selectedProgram: $selectedProgram
                )
            }
            .sheet(isPresented: $showCreateProgram) {
                CreateTrainingProgramView(
                    squadId: squad.id ?? ""
                ) { program in
                    selectedProgram = program
                }
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .alert("Course en cours", isPresented: $showJoinRaceDialog) {
                Button("Annuler", role: .cancel) {
                    // Retourner à l'étape 1 pour changer le type
                    withAnimation {
                        currentStep = .basicInfo
                        isRace = false
                    }
                }
                Button("Rejoindre la course") {
                    joinActiveRace()
                }
            } message: {
                if let race = activeRaceSession {
                    Text("Une course est déjà en cours dans votre squad. Voulez-vous la rejoindre ?")
                } else {
                    Text("Une course est déjà active.")
                }
            }
            .alert("Session déjà active", isPresented: $showUserActiveSessionAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
                Button("Voir ma session") {
                    // TODO: Naviguer vers la session active
                    dismiss()
                }
            } message: {
                Text("Vous avez déjà une session active dans cette squad. Vous devez d'abord la terminer avant d'en créer une nouvelle.")
            }
            .task {
                // Charger la course active au démarrage
                await checkForActiveRace()
                
                // Vérifier si l'utilisateur a déjà une session active
                await checkForUserActiveSession()
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(CreateSessionStep.allCases, id: \.self) { step in
                VStack(spacing: 4) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.coralAccent : Color.white.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay {
                            if step.rawValue < currentStep.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    
                    Text(step.title)
                        .font(.caption2)
                        .foregroundColor(step == currentStep ? .white : .white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                
                if step != CreateSessionStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.coralAccent : Color.white.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: 30)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Step 1: Basic Info
    
    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            // Header (remplace SessionStepHeader)
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
                    Text("Informations de base")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Définissez le type de session")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Session title
            VStack(alignment: .leading, spacing: 8) {
                Text("Titre de la session")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                TextField("Ex: Course du samedi matin", text: $sessionTitle)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundColor(.white)
            }
            
            // 🏁 Avertissement si une course est active
            if let race = activeRaceSession, isRace {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Course déjà active")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Text("Vous pourrez la rejoindre à l'étape suivante")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange, lineWidth: 2)
                }
            }
            
            // Race toggle
            Toggle(isOn: $isRace) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session de type Course")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(activeRaceSession != nil
                         ? "Une course est déjà active - Vous pourrez la rejoindre"
                         : "Une seule session de course peut être active à la fois")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .tint(.coralAccent)
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Theme selection
            if !isRace {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Thème de l'entraînement")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    ForEach(TrainingTheme.allCases, id: \.self) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: selectedTheme == theme
                        ) {
                            selectedTheme = theme
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Location
    
    private var locationStep: some View {
        VStack(spacing: 20) {
            // Header (remplace SessionStepHeader)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.coralAccent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mappin.circle.fill")
                        .font(.headline)
                        .foregroundColor(.coralAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lieu de rendez-vous")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Où les coureurs vont-ils se retrouver ?")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Toggle location
            Toggle(isOn: $hasLocation) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Définir un lieu de RDV")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text("Les participants sauront où vous rejoindre")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .tint(.coralAccent)
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if hasLocation {
                // Location display or picker
                if let coordinate = selectedCoordinate, !locationName.isEmpty {
                    LocationDisplayCard(
                        locationName: locationName,
                        coordinate: coordinate,
                        onEdit: {
                            showLocationPicker = true
                        },
                        onRemove: {
                            locationName = ""
                            selectedCoordinate = nil
                            hasLocation = false
                        }
                    )
                } else {
                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Choisir un lieu")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.coralAccent, Color.pinkAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Program
    
    private var programStep: some View {
        VStack(spacing: 20) {
            // Header (remplace SessionStepHeader)
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.coralAccent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "doc.text.fill")
                        .font(.headline)
                        .foregroundColor(.coralAccent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Programme d'entraînement")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Optionnel - Définissez des objectifs")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Toggle program
            Toggle(isOn: $hasProgram) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Associer un programme")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text("Objectifs, allure, fractionné...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .tint(.coralAccent)
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if hasProgram {
                if let program = selectedProgram {
                    // Display selected program
                    TrainingProgramCard(
                        program: program,
                        onEdit: {
                            showProgramPicker = true
                        },
                        onRemove: {
                            selectedProgram = nil
                            hasProgram = false
                        }
                    )
                } else {
                    // Choose or create program
                    VStack(spacing: 12) {
                        Button {
                            showProgramPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Choisir un programme")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            showCreateProgram = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Créer un nouveau programme")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.coralAccent, Color.pinkAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Review
    
    private var reviewStep: some View {
        VStack(spacing: 20) {
            // Header (remplace SessionStepHeader)
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
                    Text("Vérifiez les informations")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 16) {
                // Title
                ReviewRow(label: "Titre", value: sessionTitle.isEmpty ? "Sans titre" : sessionTitle)
                
                // Type
                ReviewRow(label: "Type", value: isRace ? "🏁 Course" : selectedTheme.displayName)
                
                // Location
                if hasLocation, !locationName.isEmpty {
                    ReviewRow(label: "Lieu", value: locationName)
                } else {
                    ReviewRow(label: "Lieu", value: "Aucun lieu défini")
                }
                
                // Program
                if hasProgram, let program = selectedProgram {
                    ReviewRow(label: "Programme", value: program.name)
                    ReviewRow(label: "Objectifs", value: program.objectiveSummary)
                } else {
                    ReviewRow(label: "Programme", value: "Aucun programme")
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button
            if currentStep != .basicInfo {
                Button {
                    withAnimation {
                        currentStep = CreateSessionStep(rawValue: currentStep.rawValue - 1) ?? .basicInfo
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isCreating)
            }
            
            // Next/Create button
            Button {
                handleNextAction()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep == .review ? "Créer la session" : "Suivant")
                            .font(.headline)
                        
                        if currentStep != .review {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isCreating || !canProceed)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .basicInfo:
            return !sessionTitle.isEmpty
        case .location:
            return !hasLocation || (selectedCoordinate != nil && !locationName.isEmpty)
        case .program:
            return !hasProgram || selectedProgram != nil
        case .review:
            return true
        }
    }
    
    private func handleNextAction() {
        if currentStep == .review {
            createSession()
        } else {
            // 🏁 Si on passe à l'étape suivante et que c'est une course, vérifier
            if currentStep == .basicInfo && isRace {
                Task {
                    await checkAndProceedIfRace()
                }
            } else {
                withAnimation {
                    currentStep = CreateSessionStep(rawValue: currentStep.rawValue + 1) ?? .review
                }
            }
        }
    }
    
    // MARK: - Check for Active Race
    
    /// Vérifie s'il existe déjà une course active
    private func checkForActiveRace() async {
        guard let squadId = squad.id else { return }
        
        do {
            activeRaceSession = try await SessionService.shared.getActiveRaceSession(squadId: squadId)
        } catch {
            Logger.logError(error, context: "checkForActiveRace", category: .session)
        }
    }
    
    /// Vérifie si l'utilisateur a déjà une session active dans cette squad
    private func checkForUserActiveSession() async {
        guard let squadId = squad.id,
              let userId = AuthService.shared.currentUserId else { return }
        
        do {
            userActiveSession = try await SessionService.shared.getUserActiveSession(
                squadId: squadId,
                userId: userId
            )
            
            // Si l'utilisateur a déjà une session active, afficher l'alerte
            if userActiveSession != nil {
                await MainActor.run {
                    showUserActiveSessionAlert = true
                }
            }
        } catch {
            Logger.logError(error, context: "checkForUserActiveSession", category: .session)
        }
    }
    
    /// Vérifie avant de créer une course
    private func checkAndProceedIfRace() async {
        guard let squadId = squad.id else { return }
        
        do {
            if let existingRace = try await SessionService.shared.getActiveRaceSession(squadId: squadId) {
                // Une course existe déjà
                await MainActor.run {
                    activeRaceSession = existingRace
                    showJoinRaceDialog = true
                }
            } else {
                // Pas de course active, on peut continuer
                await MainActor.run {
                    withAnimation {
                        currentStep = CreateSessionStep(rawValue: currentStep.rawValue + 1) ?? .review
                    }
                }
            }
        } catch {
            Logger.logError(error, context: "checkAndProceedIfRace", category: .session)
            await MainActor.run {
                errorMessage = "Impossible de vérifier les courses actives"
            }
        }
    }
    
    /// Rejoint la course active
    private func joinActiveRace() {
        guard let race = activeRaceSession,
              let sessionId = race.id,
              let userId = AuthService.shared.currentUserId else {
            errorMessage = "Impossible de rejoindre la course"
            return
        }
        
        Task {
            do {
                // Rejoindre la session
                try await SessionService.shared.joinSession(sessionId: sessionId, userId: userId)
                
                Logger.logSuccess("✅ Course rejointe avec succès", category: .session)
                
                // Fermer la sheet
                dismiss()
                
                // Notifier
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSessionCreated?()
                }
                
            } catch {
                errorMessage = error.localizedDescription
                Logger.logError(error, context: "joinActiveRace", category: .session)
            }
        }
    }
    
    // MARK: - Create Session
    
    private func createSession() {
        guard let squadId = squad.id else {
            errorMessage = "Squad ID non valide"
            return
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isCreating = true
        
        Task {
            do {
                // 🚫 Vérification : L'utilisateur a-t-il déjà une session active ?
                if let existingSession = try await SessionService.shared.getUserActiveSession(squadId: squadId, userId: userId) {
                    isCreating = false
                    userActiveSession = existingSession
                    showUserActiveSessionAlert = true
                    return
                }
                
                // 🏁 Vérification finale pour les courses (sécurité)
                if isRace {
                    if let existingRace = try await SessionService.shared.getActiveRaceSession(squadId: squadId) {
                        isCreating = false
                        activeRaceSession = existingRace
                        showJoinRaceDialog = true
                        return
                    }
                }
                
                // Créer la session
                let locationGeoPoint = selectedCoordinate.map { GeoPoint(latitude: $0.latitude, longitude: $0.longitude) }
                
                let session = try await SessionService.shared.createSession(
                    squadId: squadId,
                    creatorId: userId,
                    startLocation: locationGeoPoint
                )
                
                // Update session with additional info
                if let sessionId = session.id {
                    var updateData: [String: Any] = [
                        "title": sessionTitle,
                        "activityType": isRace ? ActivityType.race.rawValue : ActivityType.training.rawValue
                    ]
                    
                    if hasLocation {
                        updateData["meetingLocationName"] = locationName
                        if let locationGeoPoint = locationGeoPoint {
                            updateData["meetingLocationCoordinate"] = locationGeoPoint
                        }
                    }
                    
                    if hasProgram, let programId = selectedProgram?.id {
                        updateData["trainingProgramId"] = programId
                        
                        // Incrémenter le compteur d'usage
                        try await TrainingProgramService.shared.incrementUsageCount(
                            programId: programId,
                            squadId: squadId
                        )
                    }
                    
                    try await SessionService.shared.updateSessionFields(
                        sessionId: sessionId,
                        fields: updateData
                    )
                }
                
                isCreating = false
                Logger.logSuccess("✅ Session créée avec succès", category: .session)
                
                dismiss()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSessionCreated?()
                }
                
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
                Logger.logError(error, context: "createSession", category: .session)
            }
        }
    }
}

// MARK: - Supporting Views

struct ThemeCard: View {
    let theme: TrainingTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: theme.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .coralAccent : .white.opacity(0.7))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.coralAccent)
                }
            }
            .padding()
            .background(isSelected ? Color.coralAccent.opacity(0.2) : Color.white.opacity(0.05))
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

struct LocationDisplayCard: View {
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(.coralAccent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(locationName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Text("Modifier")
                        .font(.caption.bold())
                        .foregroundColor(.coralAccent)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.coralAccent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: onRemove) {
                    Text("Supprimer")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TrainingProgramCard: View {
    let program: TrainingProgram
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: program.theme.icon)
                    .font(.title2)
                    .foregroundColor(.coralAccent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(program.theme.displayName)
                        .font(.caption)
                        .foregroundColor(.coralAccent)
                    
                    Text(program.objectiveSummary)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Text("Modifier")
                        .font(.caption.bold())
                        .foregroundColor(.coralAccent)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.coralAccent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: onRemove) {
                    Text("Supprimer")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Placeholder Views (à implémenter)

struct TrainingProgramPickerView: View {
    let squadId: String
    @Binding var selectedProgram: TrainingProgram?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Program Picker - À implémenter")
    }
}

struct CreateTrainingProgramView: View {
    let squadId: String
    let onProgramCreated: (TrainingProgram) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Create Program - À implémenter")
    }
}

// MARK: - Preview

#Preview {
    CreateSessionWithProgramView(squad: SquadModel(
        name: "Marathon Paris 2024",
        description: "Préparation marathon",
        inviteCode: "ABC123",
        creatorId: "user1",
        members: ["user1": .admin]
    ))
    .preferredColorScheme(.dark)
}
