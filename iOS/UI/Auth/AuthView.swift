//
//  AuthView.swift
//  Scanio
//
//  Authentication view for sign in and sign up
//

import SwiftUI

struct AuthView: View {
    @Environment(\.dismiss) var dismiss

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var userName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingConfirmationAlert = false

    var onAuthSuccess: (() -> Void)?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo or title
                    VStack(spacing: 8) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.accentColor)

                        Text("Scanio")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(isSignUp ? "Créer un compte" : "Connexion")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        if isSignUp {
                            TextField("Nom d'utilisateur", text: $userName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.username)
                                .autocapitalization(.none)
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Mot de passe", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .padding(.horizontal)

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    // Submit button
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "S'inscrire" : "Se connecter")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    // Toggle sign up/sign in
                    Button(action: {
                        isSignUp.toggle()
                        errorMessage = nil
                    }) {
                        Text(isSignUp ? "Déjà un compte? Se connecter" : "Pas de compte? S'inscrire")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert("Email de confirmation envoyé", isPresented: $showingConfirmationAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Veuillez vérifier votre email et cliquer sur le lien de confirmation pour activer votre compte.")
            }
        }
    }

    private func handleAuth() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isSignUp {
                    _ = try await SupabaseManager.shared.signUp(
                        email: email,
                        password: password,
                        userName: userName.isEmpty ? nil : userName
                    )
                    isLoading = false
                    showingConfirmationAlert = true
                } else {
                    _ = try await SupabaseManager.shared.signIn(
                        email: email,
                        password: password
                    )
                    isLoading = false
                    onAuthSuccess?()
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    AuthView()
}
