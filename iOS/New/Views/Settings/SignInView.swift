//
//  SignInView.swift
//  Scanio
//
//  Sign in view for existing accounts
//

import SwiftUI

struct SignInView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingResendConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Mot de passe", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Connexion")
                }
                
                Section {
                    Button {
                        Task {
                            await signIn()
                        }
                    } label: {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Se connecter")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
                
                Section {
                    Button("Renvoyer l'email de confirmation") {
                        showingResendConfirmation = true
                    }
                    .disabled(email.isEmpty)
                } footer: {
                    Text("Si vous n'avez pas reçu l'email de confirmation, vous pouvez le renvoyer ici.")
                }
            }
            .navigationTitle("Connexion")
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
            .alert("Renvoyer l'email de confirmation", isPresented: $showingResendConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Renvoyer") {
                    Task {
                        await resendConfirmation()
                    }
                }
            } message: {
                Text("Un nouvel email de confirmation sera envoyé à \(email)")
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signIn() async {
        isLoading = true
        
        do {
            _ = try await SupabaseManager.shared.signIn(
                email: email,
                password: password
            )
            
            // Success - reload profile
            await viewModel.loadProfile()
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
    
    private func resendConfirmation() async {
        do {
            try await SupabaseManager.shared.resendConfirmationEmail(email: email)
            
            await MainActor.run {
                errorMessage = "Email de confirmation envoyé!"
                showError = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    SignInView(viewModel: ProfileViewModel())
}

