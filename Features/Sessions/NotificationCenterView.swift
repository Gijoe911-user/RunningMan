//
//  NotificationCenterView.swift
//  RunningMan
//
//  Centre de notifications avec messages vocaux et texte
//

import SwiftUI

struct NotificationCenterView: View {
    
    @StateObject private var messageService = VoiceMessageService.shared
    @StateObject private var ttsService = TextToSpeechService.shared
    @Environment(SquadViewModel.self) private var squadsVM
    
    @State private var showingCompose = false
    @State private var selectedFilter: MessageFilter = .all
    
    enum MessageFilter: String, CaseIterable {
        case all = "Tous"
        case unread = "Non lus"
        case voice = "Vocaux"
        case text = "Texte"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter tabs
                    filterTabs
                    
                    // Messages list
                    messagesList
                }
            }
            .navigationTitle("Centre de notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCompose = true
                    } label: {
                        Image(systemName: "plus.message.fill")
                            .foregroundColor(.coralAccent)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingCompose) {
                ComposeMessageView()
            }
            .task {
                if let userId = AuthService.shared.currentUserId {
                    messageService.startListeningForMessages(userId: userId)
                }
            }
        }
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MessageFilter.allCases, id: \.self) { filter in
                    filterTabButton(for: filter)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }
    
    private func filterTabButton(for filter: MessageFilter) -> some View {
        Button {
            withAnimation {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(.subheadline.bold())
                
                if filter == .unread && !messageService.unreadMessages.isEmpty {
                    Text("\(messageService.unreadMessages.count)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.coralAccent)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if selectedFilter == filter {
                    Color.coralAccent
                } else {
                    Color.clear.background(.ultraThinMaterial)
                }
            }
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Messages List
    
    private var messagesList: some View {
        Group {
            if filteredMessages.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredMessages) { message in
                            MessageRow(message: message)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var filteredMessages: [VoiceMessage] {
        let messages = messageService.recentMessages
        
        switch selectedFilter {
        case .all:
            return messages
        case .unread:
            return messages.filter { !$0.isRead }
        case .voice:
            return messages.filter { $0.messageType == .voice }
        case .text:
            return messages.filter { $0.messageType == .text }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Aucun message")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text("Commencez par envoyer un message à votre Squad !")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Message Row

struct MessageRow: View {
    let message: VoiceMessage
    
    @StateObject private var messageService = VoiceMessageService.shared
    @State private var isPlaying = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Sender avatar
            Circle()
                .fill(message.isRead ? Color.gray.opacity(0.3) : Color.coralAccent.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(message.isRead ? .gray : .coralAccent)
                }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(message.senderName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Message type badge
                HStack(spacing: 8) {
                    Image(systemName: message.messageType == .voice ? "waveform" : "text.bubble.fill")
                        .font(.caption2)
                    
                    Text(message.recipientType.displayName)
                        .font(.caption2)
                }
                .foregroundColor(.blueAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blueAccent.opacity(0.2))
                .clipShape(Capsule())
                
                // Content
                if message.messageType == .text, let text = message.textContent {
                    Text(text)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                } else if message.messageType == .voice {
                    voiceMessagePlayer
                }
                
                // Read status
                if !message.isRead {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.coralAccent)
                            .frame(width: 6, height: 6)
                        
                        Text("Non lu")
                            .font(.caption2.bold())
                            .foregroundColor(.coralAccent)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(message.isRead ? Color.clear : Color.coralAccent.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var voiceMessagePlayer: some View {
        HStack {
            Button {
                Task {
                    if isPlaying {
                        messageService.stopPlayback()
                        isPlaying = false
                    } else {
                        try? await messageService.playVoiceMessage(message)
                        isPlaying = true
                    }
                }
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.coralAccent)
            }
            
            // Waveform visualization (simplified)
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.coralAccent.opacity(0.3))
                        .frame(width: 3, height: CGFloat.random(in: 8...24))
                }
            }
            
            if let duration = message.audioDuration {
                Text(formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }
    
    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: message.timestamp, relativeTo: Date())
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Compose Message View

struct ComposeMessageView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SquadViewModel.self) private var squadsVM
    
    @StateObject private var messageService = VoiceMessageService.shared
    @StateObject private var trackingManager = TrackingManager.shared
    
    @State private var selectedScope: SharingScope = .allMySquads
    @State private var selectedSquad: SquadModel?
    @State private var selectedRecipient: String?
    @State private var messageText = ""
    @State private var messageType: MessageType = .text
    @State private var isRecording = false
    @State private var recordedAudioURL: URL?
    @State private var isSending = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Scope selector
                        scopeSelector
                        
                        // Recipient selector
                        if selectedScope == .allMySquads {
                            squadSelector
                        } else if selectedScope == .onlyOne {
                            recipientSelector
                        }
                        
                        // Message type
                        messageTypeToggle
                        
                        // Message input
                        if messageType == .text {
                            textInput
                        } else {
                            voiceRecorder
                        }
                        
                        // Send button
                        sendButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Nouveau message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        if isRecording {
                            messageService.cancelRecording()
                        }
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                }
            }
        }
    }
    
    // MARK: - Scope Selector
    
    private var scopeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Envoyer à")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.7))
            
            ForEach(SharingScope.allCases) { scope in
                scopeButton(for: scope)
            }
        }
    }
    
    private func scopeButton(for scope: SharingScope) -> some View {
        let isSelected = selectedScope == scope
        let isDisabled = scope == .allMySessions && trackingManager.activeTrackingSession == nil
        
        return Button {
            selectedScope = scope
        } label: {
            HStack {
                Image(systemName: scope.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .coralAccent : .white.opacity(0.6))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(scope.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(scope.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.coralAccent)
                }
            }
            .padding()
            .background {
                if isSelected {
                    Color.coralAccent.opacity(0.2)
                } else {
                    Color.clear.background(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
    
    // MARK: - Squad Selector
    
    private var squadSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choisir une Squad")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.7))
            
            ForEach(squadsVM.userSquads) { squad in
                squadButton(for: squad)
            }
        }
    }
    
    private func squadButton(for squad: SquadModel) -> some View {
        let isSelected = selectedSquad?.id == squad.id
        
        return Button {
            selectedSquad = squad
        } label: {
            HStack {
                Circle()
                    .fill(Color.coralAccent.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.coralAccent)
                            .font(.callout)
                    }
                
                Text(squad.name)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.coralAccent)
                }
            }
            .padding()
            .background {
                if isSelected {
                    Color.coralAccent.opacity(0.2)
                } else {
                    Color.clear.background(.ultraThinMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Recipient Selector
    
    private var recipientSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choisir un destinataire")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.7))
            
            Text("Cette fonctionnalité sera disponible prochainement")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
    
    // MARK: - Message Type Toggle
    
    private var messageTypeToggle: some View {
        HStack(spacing: 0) {
            Button {
                messageType = .text
            } label: {
                HStack {
                    Image(systemName: "text.bubble.fill")
                    Text("Texte")
                }
                .font(.subheadline.bold())
                .foregroundColor(messageType == .text ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(messageType == .text ? Color.coralAccent : Color.clear)
            }
            
            Button {
                messageType = .voice
            } label: {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("Vocal")
                }
                .font(.subheadline.bold())
                .foregroundColor(messageType == .voice ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(messageType == .voice ? Color.coralAccent : Color.clear)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Text Input
    
    private var textInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message")
                .font(.subheadline.bold())
                .foregroundColor(.white.opacity(0.7))
            
            TextEditor(text: $messageText)
                .frame(minHeight: 120)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
        }
    }
    
    // MARK: - Voice Recorder
    
    private var voiceRecorder: some View {
        VStack(spacing: 16) {
            if isRecording {
                // Recording in progress
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "waveform")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                    
                    Text(formatDuration(messageService.recordingDuration))
                        .font(.title2.monospacedDigit())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        Button {
                            messageService.cancelRecording()
                            isRecording = false
                            recordedAudioURL = nil
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                                
                                Text("Annuler")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Button {
                            let result = messageService.stopRecording()
                            recordedAudioURL = result.url
                            isRecording = false
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                                
                                Text("Terminer")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.vertical, 40)
            } else if recordedAudioURL != nil {
                // Recording complete
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Message vocal enregistré")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Button("Réenregistrer") {
                        recordedAudioURL = nil
                    }
                    .font(.caption)
                    .foregroundColor(.coralAccent)
                }
                .padding(.vertical, 40)
            } else {
                // Ready to record
                Button {
                    Task {
                        isRecording = true
                        recordedAudioURL = try? await messageService.startRecording()
                    }
                } label: {
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.coralAccent.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "mic.fill")
                                    .font(.title)
                                    .foregroundColor(.coralAccent)
                            }
                        
                        Text("Maintenir pour enregistrer")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 40)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Send Button
    
    private var sendButton: some View {
        Button {
            Task {
                await sendMessage()
            }
        } label: {
            HStack {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Envoyer")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSend ? Color.coralAccent : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canSend || isSending)
    }
    
    // MARK: - Helpers
    
    private var canSend: Bool {
        if messageType == .text {
            return !messageText.isEmpty && recipientIsValid
        } else {
            return recordedAudioURL != nil && recipientIsValid
        }
    }
    
    private var recipientIsValid: Bool {
        switch selectedScope {
        case .allMySquads:
            return selectedSquad != nil
        case .allMySessions:
            return trackingManager.activeTrackingSession != nil
        case .onlyOne:
            return selectedRecipient != nil
        }
    }
    
    private func sendMessage() async {
        isSending = true
        
        do {
            let recipientId: String?
            let sessionId: String?
            let squadId: String?
            
            switch selectedScope {
            case .allMySquads:
                recipientId = selectedSquad?.id
                sessionId = nil
                squadId = selectedSquad?.id
                
            case .allMySessions:
                recipientId = trackingManager.activeTrackingSession?.id
                sessionId = trackingManager.activeTrackingSession?.id
                squadId = trackingManager.activeTrackingSession?.squadId
                
            case .onlyOne:
                recipientId = selectedRecipient
                sessionId = nil
                squadId = nil
            }
            
            if messageType == .text {
                try await messageService.sendTextMessage(
                    text: messageText,
                    recipientType: selectedScope,
                    recipientId: recipientId,
                    sessionId: sessionId,
                    squadId: squadId
                )
            } else if let audioURL = recordedAudioURL {
                try await messageService.sendVoiceMessage(
                    audioURL: audioURL,
                    duration: messageService.recordingDuration,
                    recipientType: selectedScope,
                    recipientId: recipientId,
                    sessionId: sessionId,
                    squadId: squadId
                )
            }
            
            dismiss()
        } catch {
            Logger.logError(error, context: "sendMessage", category: .service)
        }
        
        isSending = false
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    NotificationCenterView()
        .environment(SquadViewModel())
}
