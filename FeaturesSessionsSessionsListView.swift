//
//  SessionsListView.swift
//  RunningMan
//
//  Liste des sessions de course
//

import SwiftUI
import Combine

struct SessionsListView: View {
    @StateObject private var viewModel = SessionsViewModel()
    
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
                        // TODO: Créer une nouvelle session
                    } label: {
                        Image(systemName: "plus")
                    }
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
    SessionsListView()
}
