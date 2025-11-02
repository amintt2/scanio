//
//  PersonalRankingsView.swift
//  Scanio
//
//  Personal manga rankings view
//

import SwiftUI

struct PersonalRankingsView: View {
    @StateObject private var viewModel = PersonalRankingsViewModel()
    @State private var editMode: EditMode = .inactive
    @State private var rankingToEdit: PersonalRankingWithManga?

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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editMode == .inactive {
                                rankingToEdit = ranking
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteRanking(ranking)
                                }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                rankingToEdit = ranking
                            } label: {
                                Label("Modifier", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
                .onMove { source, destination in
                    Task {
                        await viewModel.moveRanking(from: source, to: destination)
                    }
                }
            }
        }
        .navigationTitle("Classement personnel")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    Text(editMode == .active ? "Terminé" : "Modifier")
                }
            }
        }
        .sheet(item: $rankingToEdit) { ranking in
            EditRankingView(ranking: ranking) { rating, notes in
                await viewModel.updateRankingDetails(ranking, rating: rating, notes: notes)
            }
        }
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
            // Favorite heart icon instead of rank number
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.title3)
                .frame(width: 30, alignment: .center)
            
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
            print("📊 Loaded \(rankings.count) rankings")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading rankings: \(error)")
        }

        isLoading = false
    }

    // Task 4.2: Move ranking (drag & drop reordering)
    func moveRanking(from source: IndexSet, to destination: Int) async {
        print("🔄 moveRanking - from: \(source.count) indexes, to: \(destination)")

        // Update local array first for immediate UI feedback
        rankings.move(fromOffsets: source, toOffset: destination)

        // Update rank positions for all items
        var updatedRankings: [PersonalRankingWithManga] = []
        for (index, var ranking) in rankings.enumerated() {
            let newPosition = index + 1
            ranking.rankPosition = newPosition
            updatedRankings.append(ranking)

            print("🔄 Updating rank: \(ranking.mangaTitle) to #\(newPosition)")

            do {
                _ = try await SupabaseManager.shared.updateRankPosition(
                    rankingId: ranking.id,
                    newPosition: newPosition
                )
            } catch {
                print("❌ Error updating rank position: \(error)")
                errorMessage = "Erreur lors de la mise à jour du classement"
            }
        }

        // Update the entire array to trigger UI refresh
        rankings = updatedRankings

        print("✅ Rankings reordered successfully")
    }

    // Task 4.2: Delete ranking
    func deleteRanking(_ ranking: PersonalRankingWithManga) async {
        print("🗑️ Deleting ranking: \(ranking.mangaTitle)")

        do {
            try await SupabaseManager.shared.deletePersonalRanking(rankingId: ranking.id)

            // Remove from local array
            if let index = rankings.firstIndex(where: { $0.id == ranking.id }) {
                rankings.remove(at: index)
            }

            print("✅ Ranking deleted successfully")
        } catch {
            print("❌ Error deleting ranking: \(error)")
            errorMessage = "Erreur lors de la suppression"
        }
    }

    // Task 4.3: Update ranking details (rating and notes)
    func updateRankingDetails(_ ranking: PersonalRankingWithManga, rating: Int?, notes: String?) async {
        print("📝 Updating ranking details for: \(ranking.mangaTitle)")
        print("📝 Rating: \(rating.map { "\($0)/10" } ?? "None")")
        print("📝 Notes: \(notes ?? "None")")

        do {
            try await SupabaseManager.shared.updateRankingDetails(
                rankingId: ranking.id,
                rating: rating,
                notes: notes
            )

            // Update local copy
            if let index = rankings.firstIndex(where: { $0.id == ranking.id }) {
                rankings[index].personalRating = rating
                rankings[index].notes = notes
            }

            // Force UI refresh
            rankings = rankings

            print("✅ Ranking details updated successfully")
        } catch {
            print("❌ Error updating ranking details: \(error)")
            errorMessage = "Erreur lors de la mise à jour"
        }
    }
}

#Preview {
    NavigationView {
        PersonalRankingsView()
    }
}

