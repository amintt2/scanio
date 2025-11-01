//
//  EditProfileView.swift
//  Scanio
//
//  Edit user profile view
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var userName: String = ""
    @State private var bio: String = ""
    @State private var avatarUrl: String = ""
    @State private var isLoading = false
    
    var body: some View {
        Form {
            Section {
                TextField("Nom d'utilisateur", text: $userName)
                    .textContentType(.username)
                    .autocapitalization(.none)
                
                TextField("URL de l'avatar", text: $avatarUrl)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            } header: {
                Text("Informations de base")
            }
            
            Section {
                TextEditor(text: $bio)
                    .frame(minHeight: 100)
            } header: {
                Text("Bio")
            } footer: {
                Text("Décrivez-vous en quelques mots")
            }
            
            Section {
                Button {
                    Task {
                        await saveProfile()
                    }
                } label: {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Enregistrer")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Modifier le profil")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            userName = viewModel.profile?.userName ?? ""
            bio = viewModel.profile?.bio ?? ""
            avatarUrl = viewModel.profile?.avatarUrl ?? ""
        }
    }
    
    private func saveProfile() async {
        isLoading = true

        do {
            let updatedProfile = try await SupabaseManager.shared.updateProfile(
                userName: userName.isEmpty ? nil : userName,
                avatarUrl: avatarUrl.isEmpty ? nil : avatarUrl,
                bio: bio.isEmpty ? nil : bio
            )

            // Update viewModel profile
            await MainActor.run {
                viewModel.profile = updatedProfile
            }

            // Reload profile
            await viewModel.loadProfile()

            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
                isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        EditProfileView(viewModel: ProfileViewModel())
    }
}

