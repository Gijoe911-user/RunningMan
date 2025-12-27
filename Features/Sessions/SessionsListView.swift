//
//  SessionsListView.swift
//  RunningMan
//
//  Liste des sessions de course
//

import SwiftUI
import Combine

struct SessionsListView: View {
    // Récupère le view model des squads depuis l'environnement (Swift macro @Observable déjà utilisée dans ton SquadViewModel)
    @Environment(SquadViewModel.self) private var squadsVM
    
    @StateObject private var viewModel = SessionsViewModel()
    @State private var configuredSquadId: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                if let session = viewModel.activeSession {
                    SessionActiveView(session: session, viewModel: viewModel)
                } else {
                    SessionsEmptyView()
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // TODO: Présenter CreateSessionView si selectedSquad est disponible
                        // Exemple:
                        // if let squad = squadsVM.selectedSquad {
                        //     sheet = .createSession(squad)
                        // }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Démarre la localisation dès l'arrivée sur l'écran
            .onAppear {
                viewModel.startLocationUpdates()
                viewModel.centerOnUserLocation()
            }
            // Configure le contexte (squadId) et écoute la session active
            .task(id: squadsVM.selectedSquad?.id) {
                guard let squadId = squadsVM.selectedSquad?.id else { return }
                // Évite de reconfigurer si déjà fait avec le même squadId
                if configuredSquadId != squadId {
                    viewModel.setContext(squadId: squadId)
                    configuredSquadId = squadId
                }
            }
        }
    }
}

struct SessionActiveView: View {
    let session: SessionModel
    @ObservedObject var viewModel: SessionsViewModel
    
    var body: some View {
        VStack {
            Text("Session Active: \(session.title ?? "Sans titre")")
                .font(.headline)
            
            if !viewModel.activeRunners.isEmpty {
                List(viewModel.activeRunners) { runner in
                    RunnerRowView(runner: runner)
                }
            } else {
                Text("Aucun runner actif")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SessionsEmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "Aucune session active",
            systemImage: "figure.run",
            description: Text("Créez ou rejoignez une session pour commencer")
        )
    }
}

struct RunnerRowView: View {
    let runner: RunnerLocation
    
    var body: some View {
        HStack {
            if let photoURL = runner.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text(runner.displayName)
                    .font(.headline)
                Text(runner.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    // Pour l’aperçu, on peut injecter un SquadViewModel mock si nécessaire
    SessionsListView()
        .environment(SquadViewModel())
}
