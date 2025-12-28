//
//  QuickMessageView.swift
//  RunningMan
//
//  Vue pour envoyer des messages rapides pendant une session
//

import SwiftUI

struct QuickMessageView: View {
    let sessionId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var messages: [QuickMessage] = []
    @State private var customMessage = ""
    @State private var isSending = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages récents
                    messagesSection
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Zone d'envoi
                    sendSection
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                }
            }
            .task {
                await observeMessages()
            }
        }
    }
    
    // MARK: - Messages Section
    
    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                // Auto-scroll au dernier message
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Aucun message")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Envoyez un message rapide à vos coéquipiers")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Send Section
    
    private var sendSection: some View {
        VStack(spacing: 16) {
            // Messages rapides prédéfinis
            quickMessagesGrid
            
            // Message personnalisé
            customMessageField
        }
        .padding()
        .background(Color.darkNavy)
    }
    
    private var quickMessagesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(QuickMessageService.quickMessages, id: \.self) { message in
                QuickMessageButton(text: message) {
                    sendQuickMessage(message)
                }
            }
        }
    }
    
    private var customMessageField: some View {
        HStack(spacing: 12) {
            TextField("Message personnalisé...", text: $customMessage)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
            
            Button {
                sendCustomMessage()
            } label: {
                Image(systemName: isSending ? "arrow.up.circle.fill" : "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(customMessage.isEmpty ? .white.opacity(0.3) : .coralAccent)
            }
            .disabled(customMessage.isEmpty || isSending)
        }
    }
    
    // MARK: - Actions
    
    private func observeMessages() async {
        for await newMessages in QuickMessageService.shared.observeMessages(sessionId: sessionId) {
            messages = newMessages
        }
    }
    
    private func sendQuickMessage(_ text: String) {
        guard let userId = AuthService.shared.currentUserId else { return }
        
        Task {
            do {
                // Récupérer le nom de l'utilisateur
                let userName = try await getUserName(userId: userId)
                
                try await QuickMessageService.shared.sendMessage(
                    sessionId: sessionId,
                    senderId: userId,
                    senderName: userName,
                    text: text
                )
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
            } catch {
                Logger.log("❌ Erreur envoi message: \(error.localizedDescription)", category: .general)
            }
        }
    }
    
    private func sendCustomMessage() {
        guard !customMessage.isEmpty else { return }
        guard let userId = AuthService.shared.currentUserId else { return }
        
        isSending = true
        let messageText = customMessage
        customMessage = ""
        
        Task {
            do {
                let userName = try await getUserName(userId: userId)
                
                try await QuickMessageService.shared.sendMessage(
                    sessionId: sessionId,
                    senderId: userId,
                    senderName: userName,
                    text: messageText
                )
                
                isSending = false
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
            } catch {
                Logger.log("❌ Erreur envoi message: \(error.localizedDescription)", category: .general)
                customMessage = messageText // Restaurer en cas d'erreur
                isSending = false
            }
        }
    }
    
    private func getUserName(userId: String) async throws -> String {
        if let user = try await AuthService.shared.getUserProfile(userId: userId) {
            return user.displayName
        }
        return "Utilisateur"
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: QuickMessage
    @State private var isCurrentUser = false
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Nom de l'expéditeur (sauf si c'est nous)
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Bulle de message
                Text(message.message)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        isCurrentUser ?
                        Color.coralAccent :
                        Color.white.opacity(0.15)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Heure
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: 260, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser {
                Spacer()
            }
        }
        .task {
            isCurrentUser = message.senderId == AuthService.shared.currentUserId
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Quick Message Button

struct QuickMessageButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Preview

#Preview {
    QuickMessageView(sessionId: "session123")
        .preferredColorScheme(.dark)
}
