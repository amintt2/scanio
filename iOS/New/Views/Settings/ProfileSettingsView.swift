//
//  ProfileSettingsView.swift
//  Scanio
//
//  User profile settings with account creation, stats, and privacy
//

import SwiftUI

struct ProfileSettingsView: View {
    @StateObject private var viewModel = ProfileViewModel()

    // Use enum to ensure only one sheet is shown at a time
    enum AuthSheet: Identifiable {
        case signUp
        case signIn

        var id: Int {
            switch self {
            case .signUp: return 0
            case .signIn: return 1
            }
        }
    }

    @State private var activeAuthSheet: AuthSheet?
    
    var body: some View {
        List {
            if viewModel.isAuthenticated {
                // Authenticated user view
                profileSection
                statsSection
                privacySection
                visibilitySection  // PHASE 5, Task 5.3
                accountSection
            } else {
                // Not authenticated view
                signInSection
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeAuthSheet) { sheet in
            switch sheet {
            case .signUp:
                SignUpView(viewModel: viewModel)
            case .signIn:
                SignInView(viewModel: viewModel)
            }
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
                        activeAuthSheet = .signUp
                    } label: {
                        Text("Créer un compte")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button {
                        activeAuthSheet = .signIn
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
                Label("Histoires lues", systemImage: "books.vertical.fill")
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

            HStack {
                Label("Commentaires", systemImage: "bubble.left.and.bubble.right.fill")
                Spacer()
                Text("\(viewModel.stats?.totalComments ?? 0)")
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

    // MARK: - Visibility Section (PHASE 5, Task 5.3)

    private var visibilitySection: some View {
        Section {
            Toggle("Afficher l'historique", isOn: Binding(
                get: { viewModel.visibilitySettings?.showHistory ?? true },
                set: { newValue in
                    Task {
                        await viewModel.updateVisibility(showHistory: newValue)
                    }
                }
            ))

            Toggle("Afficher le classement", isOn: Binding(
                get: { viewModel.visibilitySettings?.showRankings ?? true },
                set: { newValue in
                    Task {
                        await viewModel.updateVisibility(showRankings: newValue)
                    }
                }
            ))

            Toggle("Afficher les statistiques", isOn: Binding(
                get: { viewModel.visibilitySettings?.showStats ?? true },
                set: { newValue in
                    Task {
                        await viewModel.updateVisibility(showStats: newValue)
                    }
                }
            ))
        } header: {
            Text("Visibilité du profil")
        } footer: {
            Text("Choisissez ce que les autres utilisateurs peuvent voir sur votre profil public")
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
    @Published var visibilitySettings: ProfileVisibilitySettings?  // PHASE 5, Task 5.3
    @Published var isAuthenticated = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let supabase = SupabaseManager.shared

    init() {
        isAuthenticated = supabase.isAuthenticated
    }
    
    func loadProfile() async {
        print("🔵 loadProfile called")
        print("🔵 isAuthenticated: \(supabase.isAuthenticated)")

        guard supabase.isAuthenticated else {
            print("🔴 Not authenticated, clearing profile")
            isAuthenticated = false
            profile = nil
            stats = nil
            return
        }

        isAuthenticated = true
        isLoading = true

        do {
            print("🟢 Fetching profile, stats, and visibility settings...")
            async let profileTask = supabase.fetchProfile()
            async let statsTask = supabase.fetchUserStats()
            async let visibilityTask = supabase.fetchProfileVisibilitySettings()

            profile = try await profileTask
            print("🟢 Profile loaded: \(profile?.userName ?? "nil")")

            stats = try await statsTask
            print("🟢 Stats loaded: karma=\(stats?.karma ?? 0)")

            visibilitySettings = try await visibilityTask
            print("🟢 Visibility settings loaded")
        } catch {
            print("🔴 Error loading profile: \(error)")
            print("🔴 Error type: \(type(of: error))")

            // Only show error if it's not an authentication error
            if case SupabaseError.notAuthenticated = error {
                // User is not authenticated, just clear the data
                print("🔴 SupabaseError.notAuthenticated")
                isAuthenticated = false
                profile = nil
                stats = nil
            } else if case SupabaseError.profileNotFound = error {
                print("🔴 SupabaseError.profileNotFound - Creating profile...")
                // Profile doesn't exist, try to create it
                do {
                    try await supabase.createProfile()
                    // Retry loading
                    profile = try await supabase.fetchProfile()
                    stats = try await supabase.fetchUserStats()
                    print("🟢 Profile created and loaded successfully")
                } catch {
                    print("🔴 Failed to create profile: \(error)")
                    errorMessage = "Failed to create profile: \(error.localizedDescription)"
                    showError = true
                }
            } else {
                // Real error, show it to the user
                print("🔴 Other error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            }
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

    // PHASE 5, Task 5.3: Update visibility settings
    func updateVisibility(showHistory: Bool? = nil, showRankings: Bool? = nil, showStats: Bool? = nil) async {
        do {
            visibilitySettings = try await supabase.updateProfileVisibilitySettings(
                showHistory: showHistory,
                showRankings: showRankings,
                showStats: showStats
            )
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

    func refreshAuthState() {
        isAuthenticated = supabase.isAuthenticated
    }
}

#Preview {
    NavigationView {
        ProfileSettingsView()
    }
}

