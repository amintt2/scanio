//
//  SignUpView.swift
//  Scanio
//
//  Sign up view for creating new accounts
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var userName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nom d'utilisateur", text: $userName)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Mot de passe", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirmer le mot de passe", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Informations du compte")
                } footer: {
                    Text("Le mot de passe doit contenir au moins 8 caractères.")
                }
                
                Section {
                    Button {
                        Task {
                            await signUp()
                        }
                    } label: {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Créer un compte")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Un email de confirmation sera envoyé", systemImage: "envelope.fill")
                        Label("Vous devez confirmer votre email pour activer votre compte", systemImage: "checkmark.shield.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Créer un compte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Compte créé!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Un email de confirmation a été envoyé à \(email). Vérifiez votre boîte mail et cliquez sur le lien pour activer votre compte.")
            }
        }
    }

    @State private var showSuccess = false

    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !userName.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        email.contains("@")
    }

    private func signUp() async {
        isLoading = true

        do {
            _ = try await SupabaseManager.shared.signUp(
                email: email,
                password: password,
                userName: userName
            )

            // Success - show confirmation message
            await MainActor.run {
                isLoading = false
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

#Preview {
    SignUpView(viewModel: ProfileViewModel())
}

