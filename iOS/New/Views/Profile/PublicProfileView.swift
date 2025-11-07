//
//  PublicProfileView.swift
//  Scanio
//
//  PHASE 5, Task 5.1: Full public profile page
//

import SwiftUI

struct PublicProfileView: View {
    let userId: String
    @StateObject private var viewModel = PublicProfileViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(40)
                } else if let profile = viewModel.profile {
                    // Header
                    profileHeader(profile)

                    // Stats (if public)
                    if profile.isPublic, let stats = viewModel.stats {
                        statsSection(stats: stats)
                    }
                    
                    // Rankings (if visible)
                    if profile.isPublic,
                       viewModel.visibilitySettings?.showRankings == true,
                       !viewModel.rankings.isEmpty {
                        rankingsSection
                    }
                    
                    // Reading history (if visible)
                    if profile.isPublic,
                       viewModel.visibilitySettings?.showHistory == true {
                        historySection
                    }
                } else {
                    // Profile not found
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("Profil introuvable ou privé")
                            .font(.headline)
                    }
                    .padding(40)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadProfile(userId: userId)
        }
    }
    
    // MARK: - Profile Header
    
    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Text(profile.userName?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Username with online status
            HStack(spacing: 8) {
                Text(profile.userName ?? "Utilisateur")
                    .font(.title.weight(.bold))

                // Online status indicator
                if let isOnline = profile.isOnline, isOnline {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                        Text("En ligne")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if let lastSeen = profile.lastSeen {
                    Text(formatLastSeen(lastSeen))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Bio
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Karma
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("\(profile.karma) karma")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // MARK: - Stats Section
    
    private func statsSection(stats: UserStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiques")
                .font(.title2.weight(.bold))
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Chapitres lus",
                    value: "\(stats.totalChaptersRead)",
                    icon: "book.fill",
                    color: .blue
                )
                StatCard(
                    title: "Histoires lues",
                    value: "\(stats.totalMangaRead)",
                    icon: "books.vertical.fill",
                    color: .green
                )
                StatCard(
                    title: "En cours",
                    value: "\(stats.totalReading)",
                    icon: "bookmark.fill",
                    color: .purple
                )
                StatCard(
                    title: "Favoris",
                    value: "\(stats.totalFavorites)",
                    icon: "heart.fill",
                    color: .red
                )
                StatCard(
                    title: "Commentaires",
                    value: "\(stats.totalComments)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .orange
                )
                StatCard(
                    title: "Karma",
                    value: "\(stats.karma)",
                    icon: "star.fill",
                    color: .yellow
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Rankings Section
    
    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Classement personnel")
                .font(.title2.weight(.bold))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.rankings.enumerated()), id: \.element.id) { index, ranking in
                    HStack(spacing: 12) {
                        // Rank
                        ZStack {
                            Circle()
                                .fill(index < 3 ? rankColor(for: index + 1) : Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Text("#\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(index < 3 ? .white : .primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ranking.mangaTitle)
                                .font(.body.weight(.medium))
                                .lineLimit(2)
                            
                            if let rating = ranking.personalRating {
                                HStack(spacing: 2) {
                                    ForEach(0..<rating, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            
                            if let notes = ranking.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historique récent")
                .font(.title2.weight(.bold))
                .padding(.horizontal)
            
            if viewModel.history.isEmpty {
                Text("Aucun historique")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.history.prefix(10)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.mangaTitle ?? "Titre inconnu")
                                    .font(.subheadline.weight(.medium))
                                Text("Chapitre \(item.chapterNumber ?? "?")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()

                            Text(timeAgoString(from: item.lastReadAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .blue
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatLastSeen(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Vu à l'instant"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Vu il y a \(minutes) min"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Vu il y a \(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "Vu il y a \(days)j"
        }
    }
}

// MARK: - ViewModel

@MainActor
class PublicProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var stats: UserStats?
    @Published var visibilitySettings: ProfileVisibilitySettings?
    @Published var rankings: [PersonalRankingWithManga] = []
    @Published var history: [ReadingHistoryWithManga] = []
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    func loadProfile(userId: String) async {
        print("👤 Loading full profile for user: \(userId)")
        isLoading = true
        
        do {
            // Load profile
            profile = try await supabase.fetchProfile(userId: userId)
            print("👤 Profile loaded: \(profile?.userName ?? "nil")")
            
            // If public, load additional data
            if profile?.isPublic == true {
                async let statsTask = supabase.fetchUserStats(userId: userId)
                async let visibilityTask = supabase.fetchProfileVisibilitySettings(userId: userId)
                
                stats = try await statsTask
                visibilitySettings = try await visibilityTask
                
                print("👤 Stats loaded")
                print("👤 Visibility settings loaded")
                
                // Load rankings if visible
                if visibilitySettings?.showRankings == true {
                    rankings = try await supabase.fetchPersonalRankings(userId: userId, limit: 50)
                    print("👤 Rankings loaded: \(rankings.count) items")
                }
                
                // Load history if visible
                if visibilitySettings?.showHistory == true {
                    history = try await supabase.fetchReadingHistory(userId: userId, limit: 20)
                    print("👤 History loaded: \(history.count) items")
                }
            }
        } catch {
            print("❌ Error loading profile: \(error)")
        }
        
        isLoading = false
    }
}

