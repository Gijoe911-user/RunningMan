//
//  GlassCard.swift
//  RunningMan
//
//  Composant de carte glassmorphism moderne
//

import SwiftUI

/// Carte avec effet glassmorphism inspiré de la maquette
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    
    init(
        cornerRadius: CGFloat = 20,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - Glass Button

/// Bouton circulaire avec effet glass
struct GlassButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 60
    var iconSize: CGFloat = 24
    var tint: Color = .white
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(tint)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Bar

/// Barre de progression avec dégradé
struct GradientProgressBar: View {
    let progress: Double // 0.0 à 1.0
    let gradient: LinearGradient
    var height: CGFloat = 8
    var cornerRadius: CGFloat = 4
    
    init(
        progress: Double,
        colors: [Color] = [.orange, .pink],
        height: CGFloat = 8,
        cornerRadius: CGFloat = 4
    ) {
        self.progress = progress
        self.gradient = LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.2))
                
                // Progress
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Participant Badge

/// Badge circulaire pour afficher un participant
struct ParticipantBadge: View {
    let imageURL: String?
    let initial: String
    var size: CGFloat = 40
    var borderColor: Color = .white
    var borderWidth: CGFloat = 2
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // TODO: Charger l'image si disponible
            Text(initial)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Participants Stack

/// Pile de badges de participants (comme dans la maquette)
struct ParticipantsStack: View {
    let participants: [String] // User IDs ou initials
    var maxVisible: Int = 4
    var badgeSize: CGFloat = 40
    var overlap: CGFloat = 12
    
    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(participants.prefix(maxVisible).indices, id: \.self) { index in
                let initial = participants[index].prefix(1).uppercased()
                ParticipantBadge(
                    imageURL: nil,
                    initial: String(initial),
                    size: badgeSize
                )
                .zIndex(Double(maxVisible - index))
            }
            
            // Indicateur "+X" si plus de participants
            if participants.count > maxVisible {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                    
                    Text("+\(participants.count - maxVisible)")
                        .font(.system(size: badgeSize * 0.35, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: badgeSize, height: badgeSize)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            }
        }
    }
}

// MARK: - Distance Badge

/// Badge pour afficher une distance sur la carte
struct DistanceBadge: View {
    let distance: Double // en km
    var size: CGFloat = 80
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 2) {
                Text(String(format: "%.1f", distance))
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(.white)
                
                Text("km")
                    .font(.system(size: size * 0.2, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Session Card Header

/// En-tête de carte de session (comme "Run Together")
struct SessionCardHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let isActive: Bool
    let onPlayTap: () -> Void
    
    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        if isActive {
                            Image(systemName: "figure.run")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Play Button
                Button(action: onPlayTap) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Challenge Card

/// Carte de challenge (comme "Préparation Marathon")
struct ChallengeCard: View {
    let title: String
    let distance: Double
    let progress: Double
    let daysRemaining: Int
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f km", distance))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Progress Bar
                GradientProgressBar(
                    progress: progress,
                    colors: [.orange, .pink]
                )
                
                // Footer
                HStack {
                    Text("\(Int(progress * 100))% complété")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        
                        Text("\(daysRemaining) jours restants")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
    }
}

// MARK: - Action Button Bar

/// Barre de boutons d'action en bas (Micro, Photo, Messages)
struct ActionButtonBar: View {
    let onMicroTap: () -> Void
    let onPhotoTap: () -> Void
    let onMessagesTap: () -> Void
    var unreadCount: Int = 0
    
    var body: some View {
        GlassCard(
            cornerRadius: 24,
            padding: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        ) {
            HStack(spacing: 24) {
                // Micro
                ActionButton(
                    icon: "mic.fill",
                    label: "Micro",
                    color: .purple,
                    action: onMicroTap
                )
                
                Spacer()
                
                // Photo
                ActionButton(
                    icon: "camera.fill",
                    label: "Photo",
                    color: .blue,
                    action: onPhotoTap
                )
                
                Spacer()
                
                // Messages
                ZStack(alignment: .topTrailing) {
                    ActionButton(
                        icon: "message.fill",
                        label: "Messages",
                        color: .pink,
                        action: onMessagesTap
                    )
                    
                    if unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            
                            Text("\(unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 8, y: -8)
                    }
                }
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Glass Card") {
    ZStack {
        Color.darkNavy.ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassCard {
                Text("Glass Card")
                    .foregroundColor(.white)
            }
            
            GlassButton(icon: "plus", action: {})
            
            GradientProgressBar(progress: 0.67)
                .padding(.horizontal)
            
            ParticipantsStack(participants: ["Jean", "Marie", "Paul", "Sophie", "Lucas"])
            
            DistanceBadge(distance: 3.5)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Session Cards") {
    ZStack {
        Color.darkNavy.ignoresSafeArea()
        
        VStack(spacing: 16) {
            SessionCardHeader(
                title: "Run Together",
                subtitle: "4 coureurs actifs",
                icon: "figure.run.circle.fill",
                isActive: true,
                onPlayTap: {}
            )
            
            ChallengeCard(
                title: "Préparation Marathon",
                distance: 42.2,
                progress: 0.67,
                daysRemaining: 8
            )
            
            Spacer()
            
            ActionButtonBar(
                onMicroTap: {},
                onPhotoTap: {},
                onMessagesTap: {},
                unreadCount: 3
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
