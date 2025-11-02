//
//  UserProfileSheet.swift
//  Scanio
//
//  PHASE 5, Task 5.4: User profile bottom sheet (YouTube-style)
//

import SwiftUI

struct UserProfileSheet: View {
    let userId: String
    @StateObject private var viewModel = UserProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(40)
                    } else if let profile = viewModel.profile {
                        // Header with avatar and basic info
                        profileHeader(profile)
                        
                        Divider()
                            .padding(.vertical, 16)
                        
                        // Stats section (if public)
                        if profile.isPublic, let stats = viewModel.stats {
                            statsSection(stats: stats)
                            
                            Divider()
                                .padding(.vertical, 16)
                        }
                        
                        // Rankings section (if visible and public)
                        if profile.isPublic,
                           viewModel.visibilitySettings?.showRankings == true,
                           !viewModel.rankings.isEmpty {
                            rankingsSection
                            
                            Divider()
                                .padding(.vertical, 16)
                        }
                        
                        // View full profile button
                        if profile.isPublic {
                            NavigationLink {
                                PublicProfileView(userId: userId)
                            } label: {
                                HStack {
                                    Text("Voir le profil complet")
                                        .font(.subheadline.weight(.medium))
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                        }
                    } else {
                        // Profile not found or private
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Profil introuvable")
                                .font(.headline)
                        }
                        .padding(40)
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadProfile(userId: userId)
        }
    }
    
    // MARK: - Profile Header
    
    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Text(profile.userName?.prefix(1).uppercased() ?? "?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                )
            
            // Username
            Text(profile.userName ?? "Utilisateur")
                .font(.title2.weight(.bold))
            
            // Bio
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Karma
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(profile.karma) karma")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            // Public/Private badge
            HStack(spacing: 4) {
                Image(systemName: profile.isPublic ? "eye" : "eye.slash")
                    .font(.caption2)
                Text(profile.isPublic ? "Profil public" : "Profil privé")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(16)
    }
    
    // MARK: - Stats Section
    
    private func statsSection(stats: UserStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiques")
                .font(.headline)
                .padding(.horizontal, 16)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Chapitres lus",
                    value: "\(stats.totalChaptersRead)",
                    icon: "book.fill",
                    color: .blue
                )
                StatCard(
                    title: "Histoires",
                    value: "\(stats.totalMangaRead)",
                    icon: "books.vertical.fill",
                    color: .green
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
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Rankings Section
    
    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top mangas")
                    .font(.headline)
                Spacer()
                if viewModel.rankings.count > 3 {
                    Text("Top \(min(3, viewModel.rankings.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                ForEach(Array(viewModel.rankings.prefix(3).enumerated()), id: \.element.id) { index, ranking in
                    HStack(spacing: 12) {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(rankColor(for: index + 1))
                                .frame(width: 32, height: 32)
                            
                            Text("#\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                        
                        // Manga title
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ranking.mangaTitle)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            
                            if let rating = ranking.personalRating {
                                HStack(spacing: 2) {
                                    ForEach(0..<rating, id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
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
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.weight(.bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - ViewModel

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var stats: UserStats?
    @Published var visibilitySettings: ProfileVisibilitySettings?
    @Published var rankings: [PersonalRankingWithManga] = []
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    func loadProfile(userId: String) async {
        print("👤 Loading profile for user: \(userId)")
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
                    rankings = try await supabase.fetchPersonalRankings(userId: userId, limit: 10)
                    print("👤 Rankings loaded: \(rankings.count) items")
                }
            }
        } catch {
            print("❌ Error loading profile: \(error)")
        }
        
        isLoading = false
    }
}

