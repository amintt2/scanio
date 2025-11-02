//
//  EditRankingView.swift
//  Scanio
//
//  Edit personal ranking (rating and notes)
//

import SwiftUI

struct EditRankingView: View {
    let ranking: PersonalRankingWithManga
    let onSave: (Int?, String?) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var personalRating: Int
    @State private var notes: String
    @State private var isSaving = false
    
    init(ranking: PersonalRankingWithManga, onSave: @escaping (Int?, String?) async -> Void) {
        self.ranking = ranking
        self.onSave = onSave
        _personalRating = State(initialValue: ranking.personalRating ?? 0)
        _notes = State(initialValue: ranking.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text(ranking.mangaTitle)
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Note personnelle")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Note :")
                            Spacer()
                            Text(personalRating > 0 ? "\(personalRating)/10" : "Non noté")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(1...10, id: \.self) { rating in
                                Button {
                                    withAnimation {
                                        if personalRating == rating {
                                            personalRating = 0 // Unset if tapping same rating
                                        } else {
                                            personalRating = rating
                                        }
                                    }
                                } label: {
                                    Image(systemName: rating <= personalRating ? "star.fill" : "star")
                                        .foregroundColor(rating <= personalRating ? .orange : .gray)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Notes personnelles")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if notes.isEmpty {
                                    Text("Ajoutez vos notes personnelles sur ce manga...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
            .navigationTitle("Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private func saveChanges() async {
        print("💾 Saving changes for: \(ranking.mangaTitle)")
        print("💾 Rating: \(personalRating > 0 ? "\(personalRating)/10" : "None")")
        print("💾 Notes: \(notes.isEmpty ? "Empty" : notes)")
        
        isSaving = true
        
        let ratingToSave = personalRating > 0 ? personalRating : nil
        let notesToSave = notes.isEmpty ? nil : notes
        
        await onSave(ratingToSave, notesToSave)
        
        isSaving = false
        dismiss()
    }
}

#Preview {
    EditRankingView(
        ranking: PersonalRankingWithManga(
            id: "test-id",
            userId: "test-user",
            canonicalMangaId: "test-manga",
            mangaTitle: "Test Manga",
            rankPosition: 1,
            personalRating: 8,
            notes: "Great manga!",
            isFavorite: true,
            readingStatus: .reading
        ),
        onSave: { rating, notes in
            print("Saved: \(rating ?? 0)/10, \(notes ?? "")")
        }
    )
}

