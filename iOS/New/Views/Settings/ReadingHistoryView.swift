//
//  ReadingHistoryView.swift
//  Scanio
//
//  Reading history view - shows user's reading history
//

import SwiftUI

struct ReadingHistoryView: View {
    @StateObject private var viewModel = ReadingHistoryViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.history.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("Aucun historique de lecture")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Commencez à lire des mangas pour voir votre historique ici")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.history) { item in
                    ReadingHistoryRow(item: item)
                }
            }
        }
        .navigationTitle("Historique de lecture")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory()
        }
        .refreshable {
            await viewModel.loadHistory()
        }
    }
}

struct ReadingHistoryRow: View {
    let item: ReadingHistoryWithManga

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.mangaTitle)
                .font(.headline)

            HStack {
                Text("Chapitre \(item.chapterNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let chapterTitle = item.chapterTitle {
                    Text("• \(chapterTitle)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            HStack {
                if item.isCompleted {
                    Label("Terminé", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Page \(item.pageNumber)/\(item.totalPages)", systemImage: "book.pages")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(item.lastReadAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class ReadingHistoryViewModel: ObservableObject {
    @Published var history: [ReadingHistoryWithManga] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadHistory() async {
        isLoading = true

        do {
            history = try await SupabaseManager.shared.fetchReadingHistory(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationView {
        ReadingHistoryView()
    }
}

