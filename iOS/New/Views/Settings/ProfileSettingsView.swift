//
//  ProfileSettingsView.swift
//  Scanio
//
//  User profile settings with account creation, stats, and privacy
//

import SwiftUI

struct ProfileSettingsView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    
    var body: some View {
        List {
            if viewModel.isAuthenticated {
                // Authenticated user view
                profileSection
                statsSection
                privacySection
                accountSection
            } else {
                // Not authenticated view
                signInSection
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSignUp) {
            SignUpView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadProfile()
        }
        .alert("Erreur", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Une erreur est survenue")
        }
    }
    
    // MARK: - Sign In Section

    private var signInSection: some View {
        Group {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("Créez un compte pour accéder à toutes les fonctionnalités")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        showingSignUp = true
                    } label: {
                        Text("Créer un compte")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button {
                        showingSignIn = true
                    } label: {
                        Text("Se connecter")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.vertical)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Commentaires et reviews", systemImage: "bubble.left.and.bubble.right")
                    Label("Historique de lecture", systemImage: "clock.arrow.circlepath")
                    Label("Classement personnel", systemImage: "star.fill")
                    Label("Profil public", systemImage: "person.2")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            } header: {
                Text("Fonctionnalités disponibles")
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Avatar
                if let avatarUrl = viewModel.profile?.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 60, height: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.profile?.userName ?? "Utilisateur")
                        .font(.headline)
                    
                    if let bio = viewModel.profile?.bio {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(viewModel.profile?.karma ?? 0)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Label(viewModel.profile?.isPublic == true ? "Public" : "Privé", systemImage: viewModel.profile?.isPublic == true ? "eye" : "eye.slash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            
            NavigationLink("Modifier le profil") {
                EditProfileView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        Section("Statistiques") {
            HStack {
                Label("Chapitres lus", systemImage: "book.fill")
                Spacer()
                Text("\(viewModel.stats?.totalChaptersRead ?? 0)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Mangas lus", systemImage: "books.vertical.fill")
                Spacer()
                Text("\(viewModel.stats?.totalMangaRead ?? 0)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Favoris", systemImage: "heart.fill")
                Spacer()
                Text("\(viewModel.stats?.totalFavorites ?? 0)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("Terminés", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(viewModel.stats?.totalCompleted ?? 0)")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("En cours", systemImage: "book.circle.fill")
                Spacer()
                Text("\(viewModel.stats?.totalReading ?? 0)")
                    .foregroundColor(.secondary)
            }
            
            NavigationLink("Historique de lecture") {
                ReadingHistoryView()
            }
            
            NavigationLink("Classement personnel") {
                PersonalRankingsView()
            }
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section {
            Toggle("Profil public", isOn: Binding(
                get: { viewModel.profile?.isPublic ?? true },
                set: { newValue in
                    Task {
                        await viewModel.updatePrivacy(isPublic: newValue)
                    }
                }
            ))
        } header: {
            Text("Confidentialité")
        } footer: {
            Text("Si votre profil est public, les autres utilisateurs pourront voir votre classement personnel et vos statistiques.")
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Section {
            Button("Se déconnecter", role: .destructive) {
                viewModel.signOut()
            }
        }
    }
}

// MARK: - Profile ViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var stats: UserStats?
    @Published var isAuthenticated = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared
    
    init() {
        isAuthenticated = supabase.isAuthenticated
    }
    
    func loadProfile() async {
        guard supabase.isAuthenticated else {
            isAuthenticated = false
            return
        }
        
        isAuthenticated = true
        isLoading = true
        
        do {
            async let profileTask = supabase.fetchProfile()
            async let statsTask = supabase.fetchUserStats()
            
            profile = try await profileTask
            stats = try await statsTask
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func updatePrivacy(isPublic: Bool) async {
        do {
            profile = try await supabase.updateProfile(isPublic: isPublic)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func signOut() {
        supabase.signOut()
        isAuthenticated = false
        profile = nil
        stats = nil
    }
}

#Preview {
    NavigationView {
        ProfileSettingsView()
    }
}

