//
//  OnboardingWelcomeView.swift
//  Aidoku (iOS)
//
//  Welcome screen for onboarding tutorial
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let onStart: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon or illustration
            Image(systemName: "book.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.accentColor)
            
            // Welcome text
            VStack(spacing: 16) {
                Text("Bienvenue sur Scanio!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Nous allons vous guider à travers les fonctionnalités principales de l'application.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Features preview
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "globe",
                    title: "Sources",
                    description: "Ajoutez des sources de contenu"
                )
                FeatureRow(
                    icon: "books.vertical.fill",
                    title: "Bibliothèque",
                    description: "Gérez votre collection"
                )
                FeatureRow(
                    icon: "clock.fill",
                    title: "Historique",
                    description: "Retrouvez vos lectures"
                )
                FeatureRow(
                    icon: "gear",
                    title: "Paramètres",
                    description: "Personnalisez l'expérience"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    onStart()
                } label: {
                    Text("Commencer le tutoriel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    onSkip()
                } label: {
                    Text("Passer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingWelcomeView(
        onStart: { print("Start") },
        onSkip: { print("Skip") }
    )
}

