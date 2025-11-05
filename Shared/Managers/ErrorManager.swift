//
//  ErrorManager.swift
//  TomoScan
//
//  Gestion centralisée des erreurs pour l'UI
//

import Foundation
import SwiftUI

/// Gestionnaire centralisé des erreurs pour l'application
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    /// Message d'erreur actuel à afficher dans l'UI
    @Published var currentError: UserFacingError?
    
    /// Afficher l'erreur dans l'UI (sans popup)
    @Published var showError: Bool = false
    
    private init() {}
    
    /// Enregistrer une erreur pour l'afficher dans l'UI
    func handleError(_ error: Error, context: String = "") {
        let userError = UserFacingError(from: error, context: context)
        
        // Log en debug seulement
        #if DEBUG
        print("🔴 Error [\(context)]: \(error.localizedDescription)")
        #endif
        
        // Mettre à jour l'UI sur le main thread
        DispatchQueue.main.async {
            self.currentError = userError
            self.showError = true
        }
    }
    
    /// Effacer l'erreur actuelle
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showError = false
        }
    }
}

/// Erreur formatée pour l'utilisateur final
struct UserFacingError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let context: String
    
    init(from error: Error, context: String = "") {
        self.context = context
        
        // Convertir l'erreur en message utilisateur
        if let supabaseError = error as? SupabaseError {
            switch supabaseError {
            case .networkError:
                self.title = "Pas de connexion"
                self.message = "Vérifiez votre connexion internet"
                self.icon = "wifi.slash"
                
            case .authenticationFailed, .notAuthenticated:
                self.title = "Session expirée"
                self.message = "Veuillez vous reconnecter"
                self.icon = "person.crop.circle.badge.xmark"
                
            case .invalidResponse:
                self.title = "Erreur serveur"
                self.message = "Réessayez dans quelques instants"
                self.icon = "exclamationmark.triangle"
                
            case .decodingError:
                self.title = "Erreur de données"
                self.message = "Les données reçues sont invalides"
                self.icon = "doc.badge.exclamationmark"
            }
        } else {
            // Erreur générique
            self.title = "Une erreur est survenue"
            self.message = error.localizedDescription
            self.icon = "exclamationmark.circle"
        }
    }
}

/// Vue pour afficher les erreurs de manière non-intrusive
struct ErrorBannerView: View {
    @ObservedObject var errorManager = ErrorManager.shared
    
    var body: some View {
        VStack {
            if errorManager.showError, let error = errorManager.currentError {
                HStack(spacing: 12) {
                    Image(systemName: error.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(error.message)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        errorManager.clearError()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.red.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    // Auto-dismiss après 5 secondes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        errorManager.clearError()
                    }
                }
            }
            
            Spacer()
        }
        .animation(.spring(), value: errorManager.showError)
    }
}

/// Extension pour faciliter l'utilisation dans les vues
extension View {
    func withErrorBanner() -> some View {
        ZStack {
            self
            ErrorBannerView()
        }
    }
}

