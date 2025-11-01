//
//  PersonalRankingsView.swift
//  Scanio
//
//  Personal manga rankings view
//

import SwiftUI

struct PersonalRankingsView: View {
    @StateObject private var viewModel = PersonalRankingsViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.rankings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Aucun classement")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Ajoutez des mangas à votre classement personnel depuis leur page de détails")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.rankings) { ranking in
                    PersonalRankingRow(ranking: ranking)
                }
            }
        }
        .navigationTitle("Classement personnel")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRankings()
        }
        .refreshable {
            await viewModel.loadRankings()
        }
    }
}

struct PersonalRankingRow: View {
    let ranking: PersonalRankingWithManga
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank position
            Text("#\(ranking.rankPosition)")
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(width: 40, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ranking.mangaTitle)
                        .font(.headline)
                    
                    if ranking.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 8) {
                    if let rating = ranking.personalRating {
                        HStack(spacing: 2) {
                            ForEach(0..<rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            ForEach(rating..<10, id: \.self) { _ in
                                Image(systemName: "star")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Text(statusText(ranking.readingStatus))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(ranking.readingStatus).opacity(0.2))
                        .foregroundColor(statusColor(ranking.readingStatus))
                        .cornerRadius(4)
                }
                
                if let notes = ranking.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusText(_ status: ReadingStatus) -> String {
        switch status {
        case .reading: return "En cours"
        case .completed: return "Terminé"
        case .onHold: return "En pause"
        case .dropped: return "Abandonné"
        case .planToRead: return "À lire"
        }
    }

    private func statusColor(_ status: ReadingStatus) -> Color {
        switch status {
        case .reading: return .blue
        case .completed: return .green
        case .onHold: return .orange
        case .dropped: return .red
        case .planToRead: return .purple
        }
    }
}

@MainActor
class PersonalRankingsViewModel: ObservableObject {
    @Published var rankings: [PersonalRankingWithManga] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadRankings() async {
        isLoading = true
        
        do {
            rankings = try await SupabaseManager.shared.fetchPersonalRankings(limit: 100)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    NavigationView {
        PersonalRankingsView()
    }
}

