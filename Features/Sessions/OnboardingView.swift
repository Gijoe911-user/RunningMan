//
//  OnboardingView.swift
//  RunningMan
//
//  Vue d'onboarding interactive avec lecture vocale
//

import SwiftUI

struct OnboardingView: View {
    
    let configuration: OnboardingConfiguration
    let onComplete: () -> Void
    
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var currentStep = 0
    @State private var showingDetail = false
    @State private var isAutoPlaying = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        configuration: OnboardingConfiguration = .default,
        onComplete: @escaping () -> Void = {}
    ) {
        self.configuration = configuration
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Steps
                TabView(selection: $currentStep) {
                    ForEach(Array(configuration.steps.enumerated()), id: \.element.id) { index, step in
                        stepView(step: step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Controls
                controls
            }
        }
        .onChange(of: currentStep) { _, newValue in
            if isAutoPlaying {
                speakCurrentStep()
            }
        }
        .sheet(isPresented: $showingDetail) {
            detailView(step: configuration.steps[currentStep])
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    ttsService.stop()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Bouton lecture audio globale
                Button {
                    if ttsService.isSpeaking {
                        ttsService.stop()
                        isAutoPlaying = false
                    } else {
                        isAutoPlaying = true
                        ttsService.speakOnboarding(configuration.fullSpeechText)
                    }
                } label: {
                    Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .foregroundColor(ttsService.isSpeaking ? .coralAccent : .white.opacity(0.7))
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                Text(configuration.welcomeTitle)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(configuration.welcomeSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Step View
    
    private func stepView(step: OnboardingStep) -> some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorForName(step.color).opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: step.icon)
                    .font(.system(size: 50))
                    .foregroundColor(colorForName(step.color))
            }
            .padding(.top, 40)
            
            // Number badge
            Text("Étape \(step.number)")
                .font(.caption.bold())
                .foregroundColor(colorForName(step.color))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(colorForName(step.color).opacity(0.2))
                .clipShape(Capsule())
            
            // Title
            Text(step.title)
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Read aloud button
            HStack(spacing: 16) {
                Button {
                    speakCurrentStep()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2")
                        Text("Lire cette étape")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(colorForName(step.color))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(colorForName(step.color).opacity(0.2))
                    .clipShape(Capsule())
                }
                
                Button {
                    showingDetail = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                        Text("En savoir plus")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Controls
    
    private var controls: some View {
        HStack {
            // Previous button
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Précédent")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Next or complete button
            Button {
                if currentStep < configuration.steps.count - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    ttsService.stop()
                    onComplete()
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentStep < configuration.steps.count - 1 ? "Suivant" : "Commencer")
                        .font(.headline)
                    
                    Image(systemName: currentStep < configuration.steps.count - 1 ? "chevron.right" : "checkmark")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.coralAccent, .pinkAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .coralAccent.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    // MARK: - Detail View
    
    private func detailView(step: OnboardingStep) -> some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Icon header
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(colorForName(step.color).opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: step.icon)
                                    .font(.system(size: 44))
                                    .foregroundColor(colorForName(step.color))
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        
                        // Title
                        Text(step.title)
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        
                        Divider()
                            .background(.white.opacity(0.3))
                        
                        // Detailed explanation
                        Text(step.detailedExplanation)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(6)
                        
                        // Read button
                        Button {
                            ttsService.speakOnboarding(step.detailedExplanation)
                        } label: {
                            HStack {
                                Image(systemName: "speaker.wave.3")
                                Text("Lire l'explication complète")
                                Spacer()
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(colorForName(step.color))
                            .padding()
                            .background(colorForName(step.color).opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Étape \(step.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        ttsService.stop()
                        showingDetail = false
                    }
                    .foregroundColor(.coralAccent)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func speakCurrentStep() {
        let step = configuration.steps[currentStep]
        ttsService.stop()
        ttsService.speakOnboarding(step.speechText)
    }
    
    private func colorForName(_ name: String) -> Color {
        switch name {
        case "coralAccent": return .coralAccent
        case "pinkAccent": return .pinkAccent
        case "blueAccent": return .blueAccent
        case "greenAccent": return Color.green
        default: return .coralAccent
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView {
        print("Onboarding terminé")
    }
}
