//
//  CreateSessionView.swift
//  RunningMan
//
//  Vue pour créer une nouvelle session d'entraînement
//

import SwiftUI
import FirebaseFirestore

struct CreateSessionView: View {
    let squad: SquadModel
    let onSessionCreated: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SquadViewModel.self) private var squadVM
    
    @State private var sessionMode: SessionMode = .immediate  // 🆕 Mode session
    @State private var activityType: ActivityType = .training
    @State private var targetDistance: String = ""
    @State private var targetDuration: String = ""
    @State private var useQuickDistance = true  // ✅ Toggle pour distance rapide
    @State private var quickDistance: Double = 5.0  // ✅ Distance pré-définie
    
    // 🆕 Planification
    @State private var scheduledDate = Date()
    @State private var scheduledTime = Date()
    @State private var sessionTitle = ""
    @State private var sessionDescription = ""
    
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    // 🆕 Mode de session
    enum SessionMode: String, CaseIterable {
        case immediate = "Démarrer maintenant"
        case scheduled = "Planifier"
        
        var icon: String {
            switch self {
            case .immediate: return "play.circle.fill"
            case .scheduled: return "calendar.badge.clock"
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // 🆕 Mode de session (Immédiat vs Planifié)
                        sessionModeSection
                        
                        // Type de session
                        sessionTypeSection
                        
                        // 🆕 Détails si planifié
                        if sessionMode == .scheduled {
                            schedulingSection
                        }
                        
                        // Objectifs
                        goalsSection
                        
                        // Bouton Créer
                        createButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
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
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "figure.run")
                        .font(.title)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 4) {
                Text("Créer une session")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("pour \(squad.name)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 🆕 Session Mode Section
    
    private var sessionModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quand ?")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(SessionMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            sessionMode = mode
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                            
                            Text(mode.rawValue)
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(sessionMode == mode ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            sessionMode == mode
                            ? LinearGradient(
                                colors: [Color.coralAccent, Color.pinkAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if sessionMode == mode {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.coralAccent, lineWidth: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - 🆕 Scheduling Section (si planifié)
    
    private var schedulingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Détails de la planification")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Titre de la session
                VStack(alignment: .leading, spacing: 8) {
                    Label("Titre de la session", systemImage: "text.cursor")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    TextField("Ex: Course matinale", text: $sessionTitle)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                }
                
                // Date
                VStack(alignment: .leading, spacing: 8) {
                    Label("Date", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    DatePicker("", selection: $scheduledDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.coralAccent)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Heure
                VStack(alignment: .leading, spacing: 8) {
                    Label("Heure de départ", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 100)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Description optionnelle
                VStack(alignment: .leading, spacing: 8) {
                    Label("Description (optionnel)", systemImage: "text.alignleft")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    TextEditor(text: $sessionDescription)
                        .frame(height: 80)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Session Type Section
    
    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type de session")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    SessionTypeCard(
                        type: type,
                        isSelected: activityType == type
                    ) {
                        activityType = type
                    }
                }
            }
        }
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectifs (optionnel)")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Distance - Mode Rapide
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Distance cible", systemImage: "location.fill")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                useQuickDistance.toggle()
                                // Vider le champ personnalisé lors du retour au mode rapide
                                if useQuickDistance {
                                    targetDistance = ""
                                }
                            }
                        } label: {
                            Text(useQuickDistance ? "Personnalisé" : "Rapide")
                                .font(.caption)
                                .foregroundColor(.coralAccent)
                        }
                    }
                    
                    if useQuickDistance {
                        // ✅ Picker pour sélection rapide
                        Picker("Distance", selection: $quickDistance) {
                            Text("1 km").tag(1.0)
                            Text("3 km").tag(3.0)
                            Text("5 km").tag(5.0)
                            Text("10 km").tag(10.0)
                            Text("15 km").tag(15.0)
                            Text("21 km").tag(21.1)
                            Text("42 km").tag(42.2)
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        // ✅ TextField avec binding filtré pour saisie personnalisée
                        HStack {
                            TextField("Ex: 10", text: filteredDistanceBinding)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
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
                
                // Durée
                VStack(alignment: .leading, spacing: 8) {
                    Label("Durée cible", systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        TextField("Ex: 60", text: filteredDurationBinding)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
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
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Filtered Bindings
    
    /// Binding filtré pour la distance (uniquement chiffres et un point/virgule)
    private var filteredDistanceBinding: Binding<String> {
        Binding(
            get: { targetDistance },
            set: { newValue in
                // Filtrer immédiatement au niveau du binding
                var filtered = newValue.filter { "0123456789.,".contains($0) }
                
                // Remplacer les virgules par des points
                filtered = filtered.replacingOccurrences(of: ",", with: ".")
                
                // Ne garder qu'un seul point
                if filtered.filter({ $0 == "." }).count > 1 {
                    var result = ""
                    var dotSeen = false
                    for char in filtered {
                        if char == "." {
                            if !dotSeen {
                                result.append(char)
                                dotSeen = true
                            }
                        } else {
                            result.append(char)
                        }
                    }
                    filtered = result
                }
                
                // Limiter à 2 décimales
                if let dotIndex = filtered.firstIndex(of: ".") {
                    let afterDot = filtered[filtered.index(after: dotIndex)...]
                    if afterDot.count > 2 {
                        let beforeDot = filtered[..<filtered.index(after: dotIndex)]
                        let twoDecimals = afterDot.prefix(2)
                        filtered = String(beforeDot) + String(twoDecimals)
                    }
                }
                
                // Limiter à 3 chiffres avant le point (999.99 km max)
                if let dotIndex = filtered.firstIndex(of: ".") {
                    let beforeDot = filtered[..<dotIndex]
                    if beforeDot.count > 3 {
                        let limited = beforeDot.prefix(3)
                        filtered = String(limited) + String(filtered[dotIndex...])
                    }
                } else if filtered.count > 3 {
                    filtered = String(filtered.prefix(3))
                }
                
                targetDistance = filtered
            }
        )
    }
    
    /// Binding filtré pour la durée (uniquement chiffres)
    private var filteredDurationBinding: Binding<String> {
        Binding(
            get: { targetDuration },
            set: { newValue in
                // Filtrer immédiatement - uniquement les chiffres
                let filtered = newValue.filter { $0.isNumber }
                // Limiter à 4 chiffres (9999 minutes max = 166 heures)
                targetDuration = String(filtered.prefix(4))
            }
        )
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button {
            createSession()
        } label: {
            HStack {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: sessionMode == .immediate ? "play.fill" : "calendar.badge.plus")
                    Text(sessionMode == .immediate ? "Créer et rejoindre" : "Planifier la session")
                        .font(.headline)
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
        .disabled(isCreating || !isFormValid)
        .opacity(isCreating || !isFormValid ? 0.6 : 1.0)
    }
    
    /// Vérifie si le formulaire est valide
    private var isFormValid: Bool {
        if sessionMode == .scheduled {
            // Pour une session planifiée, le titre est obligatoire
            return !sessionTitle.trimmingCharacters(in: .whitespaces).isEmpty
        }
        // Pour une session immédiate, toujours valide
        return true
    }
    
    // MARK: - Actions
    
    private func createSession() {
        guard let squadId = squad.id else {
            errorMessage = "Squad ID non valide"
            return
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        // Validation pour sessions planifiées
        if sessionMode == .scheduled && sessionTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Le titre de la session est obligatoire"
            return
        }
        
        isCreating = true
        
        Task {
            // ✅ FIX: Timeout de 10 secondes pour la création
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if isCreating {
                    Logger.log("⏱️ Timeout lors de la création de session", category: .session)
                    isCreating = false
                    errorMessage = "La création prend trop de temps. Vérifiez votre connexion."
                }
            }
            
            do {
                // Vérifier d'abord s'il existe déjà une session active
                Logger.log("🔍 Vérification session active pour squad: \(squadId)", category: .session)
                
                if sessionMode == .immediate {
                    if let existingSession = try await SessionService.shared.getActiveSession(squadId: squadId) {
                        Logger.log("⚠️ Une session active existe déjà: \(existingSession.id ?? "unknown")", category: .session)
                        timeoutTask.cancel()
                        isCreating = false
                        errorMessage = "Une session est déjà active pour cette squad"
                        return
                    }
                }
                
                Logger.log("🚀 Création de la session (\(sessionMode.rawValue))...", category: .session)
                
                // Combiner date et heure pour sessions planifiées
                var scheduledStartDate: Date? = nil
                if sessionMode == .scheduled {
                    let calendar = Calendar.current
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
                    
                    var combined = DateComponents()
                    combined.year = dateComponents.year
                    combined.month = dateComponents.month
                    combined.day = dateComponents.day
                    combined.hour = timeComponents.hour
                    combined.minute = timeComponents.minute
                    
                    scheduledStartDate = calendar.date(from: combined)
                }
                
                // Calculer les objectifs
                let finalDistance: Double? = {
                    if useQuickDistance {
                        return quickDistance > 0 ? quickDistance * 1000 : nil  // Convertir km -> m
                    } else if let dist = Double(targetDistance), dist > 0 {
                        return dist * 1000  // Convertir km -> m
                    }
                    return nil
                }()
                
                let finalDuration: TimeInterval? = {
                    if let dur = TimeInterval(targetDuration), dur > 0 {
                        return dur * 60  // Convertir min -> s
                    }
                    return nil
                }()
                
                // Créer la session via le service
                let createdSession = try await SessionService.shared.createSession(
                    squadId: squadId,
                    creatorId: userId,
                    startLocation: nil
                )
                
                Logger.logSuccess("✅ Session créée: \(createdSession.id ?? "unknown") - mode: \(sessionMode.rawValue)", category: .session)
                
                // 🎯 Comportement selon le mode
                if sessionMode == .scheduled {
                    // Session planifiée : rester en SCHEDULED, ne pas auto-join
                    Logger.log("📅 Session planifiée créée - visible pour tous les membres", category: .session)
                } else {
                    // Session immédiate : reste en mode SCHEDULED (spectateur par défaut)
                    // L'utilisateur devra cliquer sur "Démarrer l'activité" pour passer en mode coureur
                    Logger.log("✅ Session immédiate en mode SCHEDULED - attente action utilisateur", category: .session)
                }
                
                timeoutTask.cancel()
                isCreating = false
                
                // Fermer la sheet
                dismiss()
                
                // Notifier que la session est créée
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSessionCreated?()
                }
                
            } catch {
                timeoutTask.cancel()
                isCreating = false
                errorMessage = error.localizedDescription
                Logger.logError(error, context: "createSession", category: .session)
            }
        }
    }
}

// MARK: - Session Type Card

struct SessionTypeCard: View {
    let type: ActivityType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? colorForType : .white.opacity(0.7))
                    .frame(width: 30)
                
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colorForType)
                }
            }
            .padding()
            .background(isSelected ? colorForType.opacity(0.2) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(colorForType, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var colorForType: Color {
        switch type {
        case .training: return .coralAccent
        case .race: return .red
        case .interval: return .orange
        case .recovery: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    CreateSessionView(squad: SquadModel(
        name: "Marathon Paris 2024",
        description: "Préparation marathon",
        inviteCode: "ABC123",
        creatorId: "user1",
        members: ["user1": .admin]
    ))
    .preferredColorScheme(.dark)
}
