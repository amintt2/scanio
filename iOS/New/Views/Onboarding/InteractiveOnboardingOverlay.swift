//
//  InteractiveOnboardingOverlay.swift
//  Aidoku (iOS)
//
//  Simple onboarding overlay with Next button
//

import SwiftUI

struct InteractiveOnboardingOverlay: View {
    @ObservedObject var manager = OnboardingManager.shared
    let step: OnboardingStep
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent dark overlay
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent taps from going through
                }

            // Tutorial card
            VStack(spacing: 0) {
                Spacer()

                TutorialCard(
                    step: step,
                    isLastStep: step.id == manager.steps.count - 1,
                    onNext: onNext,
                    onSkip: onSkip
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Tutorial Card
struct TutorialCard: View {
    let step: OnboardingStep
    let isLastStep: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with step number and skip button
            HStack {
                Text("Étape \(step.id + 1)/\(OnboardingManager.shared.steps.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Button(action: onSkip) {
                    Text("Passer")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }

            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)

            // Title
            Text(step.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            // Next button
            Button(action: onNext) {
                HStack {
                    Text(isLastStep ? "Terminer" : "Suivant")
                        .font(.headline)
                        .fontWeight(.semibold)

                    if !isLastStep {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<OnboardingManager.shared.steps.count, id: \.self) { index in
                    Circle()
                        .fill(index == step.id ? Color.accentColor : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        )
    }
}

// MARK: - Preview
#if DEBUG
struct InteractiveOnboardingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveOnboardingOverlay(
            step: OnboardingStep(
                id: 0,
                title: "Ajouter des sources",
                description: "C'est ici que vous pouvez ajouter des sources de contenu compatibles Aidoku.",
                targetTab: 1,
                icon: "plus.circle.fill"
            ),
            onNext: {},
            onSkip: {}
        )
    }
}
#endif

