//
//  InteractiveOnboardingOverlay.swift
//  Aidoku (iOS)
//
//  Interactive onboarding overlay that forces user to tap the actual button
//

import SwiftUI

struct InteractiveOnboardingOverlay: View {
    @ObservedObject var manager = OnboardingManager.shared
    let step: OnboardingStep
    let onSkip: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay with cutout
                if manager.targetFrame != .zero {
                    OverlayWithCutout(targetFrame: manager.targetFrame)
                } else {
                    Color.black.opacity(0.85)
                        .ignoresSafeArea()
                }

                // Pulsing ring animation around the target (non-interactive)
                if manager.targetFrame != .zero {
                    PulsingRing(targetFrame: manager.targetFrame)
                        .allowsHitTesting(false)
                }

                // Tooltip card positioned above the tab bar
                VStack(spacing: 0) {
                    Spacer()

                    TooltipCard(
                        step: step,
                        onSkip: onSkip
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120) // Space for tab bar + some margin
                }
                .allowsHitTesting(true) // Make sure tooltip is interactive
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                manager.updateTargetFrame()
            }
        }
    }
}

// MARK: - Overlay with Cutout
struct OverlayWithCutout: View {
    let targetFrame: CGRect

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Full screen rectangle
                path.addRect(CGRect(origin: .zero, size: geometry.size))

                // Cutout rectangle (subtract this area)
                let cutoutRect = CGRect(
                    x: targetFrame.minX - 8,
                    y: targetFrame.minY - 8,
                    width: targetFrame.width + 16,
                    height: targetFrame.height + 16
                )
                path.addRoundedRect(in: cutoutRect, cornerSize: CGSize(width: 16, height: 16))
            }
            .fill(Color.black.opacity(0.85), style: FillStyle(eoFill: true))
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Pulsing Ring
struct PulsingRing: View {
    let targetFrame: CGRect
    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.accentColor, lineWidth: 4)
            .frame(width: targetFrame.width + 16, height: targetFrame.height + 16)
            .position(
                x: targetFrame.midX,
                y: targetFrame.midY
            )
            .scaleEffect(pulseScale)
            .opacity(pulseOpacity)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.3
                    pulseOpacity = 0.3
                }
            }
    }
}

// MARK: - Tooltip Card
struct TooltipCard: View {
    let step: OnboardingStep
    let onSkip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with step number
            HStack {
                Text("Étape \(step.id)/3")
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
            
            // Title
            Text(step.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            // Instruction (not a button, just info)
            HStack(spacing: 12) {
                Image(systemName: "hand.tap.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)

                Text("Appuyez sur le bouton ci-dessus pour continuer")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index == step.id - 1 ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview
#if DEBUG
struct InteractiveOnboardingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveOnboardingOverlay(
            step: OnboardingStep(
                id: 1,
                title: "Ajouter des sources",
                description: "Appuyez sur l'onglet 'Parcourir' pour découvrir et ajouter des sources de contenu.",
                targetView: .browseTab,
                tooltipPosition: .top
            ),
            onSkip: {}
        )
    }
}
#endif

