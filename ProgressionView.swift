//
//  ProgressionView.swift
//  RunningMan
//
//  Vue de progression et objectifs hebdomadaires
//

import SwiftUI

/// Vue de progression avec barre colorée et objectifs
///
/// Affiche :
/// - Indice de consistance avec barre de progression colorée
/// - Objectifs hebdomadaires en cours
/// - Bouton pour créer de nouveaux objectifs
///
/// **Design :**
/// - Barre horizontale avec dégradé selon le taux
/// - Vert (>75%), Jaune (50-75%), Rouge (<50%)
/// - Cards pour chaque objectif avec progression
///
/// - SeeAlso: `ProgressionService`, `UserModel.consistencyRate`
struct ProgressionView: View {
    
    // MARK: - Environment
    
    @StateObject private var progressionService = ProgressionService.shared
    
    // MARK: - State
    
    @State private var showCreateGoal = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let userId: String
    
    // MARK: - Initialization
    
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Barre de consistance
                    consistencyBar
                    
                    // Objectifs hebdomadaires
                    weeklyGoalsSection
                    
                    // Bouton créer objectif
                    createGoalButton
                }
                .padding()
            }
        }
        .navigationTitle("Progression")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
        .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalSheet(userId: userId)
        }
    }
    
    // MARK: - View Components
    
    /// Header avec titre et description
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.coralAccent, .pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Votre Consistance")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Suivez vos objectifs hebdomadaires et maintenez votre régularité")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    /// Barre de progression de consistance
    private var consistencyBar: some View {
        VStack(spacing: 16) {
            // Pourcentage
            HStack {
                Text("Indice de Consistance")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(progressionService.consistencyRate, specifier: "%.0f")%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorForRate)
            }
            
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fond
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                    
                    // Progression
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressionService.consistencyRate)
                }
            }
            .frame(height: 20)
            
            // Légende
            legendView
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// Légende des couleurs
    private var legendView: some View {
        HStack(spacing: 20) {
            LegendItem(color: .green, label: "Excellence (>75%)")
            LegendItem(color: .yellow, label: "Alerte (50-75%)")
            LegendItem(color: .red, label: "Critique (<50%)")
        }
        .font(.caption2)
    }
    
    /// Section objectifs hebdomadaires
    private var weeklyGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Objectifs de la semaine")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Semaine \(weekNumber)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if progressionService.currentWeekGoals.isEmpty {
                emptyGoalsView
            } else {
                ForEach(progressionService.currentWeekGoals) { goal in
                    WeeklyGoalCard(goal: goal)
                }
            }
        }
    }
    
    /// Vue vide si aucun objectif
    private var emptyGoalsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundColor(.coralAccent.opacity(0.6))
            
            Text("Aucun objectif cette semaine")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Créez un objectif pour commencer à tracker votre progression")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// Bouton pour créer un objectif
    private var createGoalButton: some View {
        Button {
            showCreateGoal = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Créer un objectif")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.coralAccent, .pinkAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Computed Properties
    
    /// Couleur selon le taux de consistance
    private var colorForRate: Color {
        switch progressionService.consistencyRate {
        case 0.75...1.0: return .green
        case 0.5..<0.75: return .yellow
        default: return .red
        }
    }
    
    /// Dégradé de couleurs pour la barre
    private var gradientColors: [Color] {
        switch progressionService.consistencyRate {
        case 0.75...1.0: return [.green, .mint]
        case 0.5..<0.75: return [.orange, .yellow]
        default: return [.red, .orange]
        }
    }
    
    /// Numéro de la semaine en cours
    private var weekNumber: Int {
        Calendar.current.component(.weekOfYear, from: Date())
    }
    
    // MARK: - Actions
    
    /// Charge les données de progression
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await progressionService.loadCurrentWeekGoals(for: userId)
            _ = try await progressionService.calculateConsistencyRate(for: userId)
        } catch {
            errorMessage = error.localizedDescription
            Logger.logError(error, context: "loadData", category: .ui)
        }
    }
}

// MARK: - Supporting Views

/// Card pour un objectif hebdomadaire
struct WeeklyGoalCard: View {
    let goal: WeeklyGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: goal.targetType.icon)
                    .foregroundColor(.coralAccent)
                
                Text(goal.targetType.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                Text("\(goal.formattedActual) / \(goal.formattedTarget)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ProgressView(value: goal.completionRate)
                    .tint(goal.isCompleted ? .green : .coralAccent)
                
                Text("\(goal.completionPercentage)% complété")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Reste à faire
            if !goal.isCompleted {
                Text("Reste : \(goal.formattedRemaining)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Item de légende
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

/// Sheet pour créer un objectif (Placeholder)
struct CreateGoalSheet: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: GoalType = .distance
    @State private var targetValue: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type d'objectif") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Valeur cible") {
                    TextField("Ex: 20", text: $targetValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Nouvel objectif")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        // TODO: Implémenter création
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProgressionView(userId: "user123")
    }
    .preferredColorScheme(.dark)
}
