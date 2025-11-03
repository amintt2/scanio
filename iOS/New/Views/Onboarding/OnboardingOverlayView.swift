//
//  OnboardingOverlayView.swift
//  Aidoku (iOS)
//
//  Overlay with spotlight effect for onboarding tutorial
//

import SwiftUI

struct OnboardingOverlayView: View {
    @ObservedObject var manager = OnboardingManager.shared
    @Binding var targetFrame: CGRect?
    
    let step: OnboardingStep
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ZStack {
            // Dark overlay with spotlight cutout
            SpotlightOverlay(targetFrame: targetFrame)
            
            // Tooltip
            if let frame = targetFrame {
                TooltipView(
                    step: step,
                    targetFrame: frame,
                    onNext: onNext,
                    onPrevious: onPrevious,
                    onSkip: onSkip,
                    currentStep: manager.currentStep,
                    totalSteps: manager.steps.count
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Spotlight Overlay
struct SpotlightOverlay: View {
    let targetFrame: CGRect?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.black.opacity(0.75)
                
                // Spotlight cutout
                if let frame = targetFrame {
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: frame.width + 16, height: frame.height + 16)
                        .position(x: frame.midX, y: frame.midY)
                        .blendMode(.destinationOut)
                }
            }
            .compositingGroup()
        }
    }
}

// MARK: - Tooltip View
struct TooltipView: View {
    let step: OnboardingStep
    let targetFrame: CGRect
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index == currentStep ? Color.accentColor : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Title
            Text(step.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Buttons
            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button("Précédent") {
                        onPrevious()
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Passer") {
                    onSkip()
                }
                .buttonStyle(.bordered)
                
                Button(currentStep == totalSteps - 1 ? "Terminer" : "Suivant") {
                    onNext()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 20)
        )
        .padding(.horizontal, 32)
        .position(tooltipPosition)
    }
    
    private var tooltipPosition: CGPoint {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        switch step.tooltipPosition {
        case .top:
            // Position above the target
            let yPos = max(targetFrame.minY - 250, 200)
            return CGPoint(x: screenWidth / 2, y: yPos)
        case .bottom:
            // Position below the target
            let yPos = min(targetFrame.maxY + 200, screenHeight - 200)
            return CGPoint(x: screenWidth / 2, y: yPos)
        case .center:
            return CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        default:
            return CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        }
    }
}

#Preview {
    OnboardingOverlayView(
        targetFrame: .constant(CGRect(x: 100, y: 700, width: 80, height: 50)),
        step: OnboardingStep(
            id: 1,
            title: "Test Step",
            description: "This is a test description for the onboarding step.",
            targetView: .browseTab,
            tooltipPosition: .top
        ),
        onNext: { print("Next") },
        onPrevious: { print("Previous") },
        onSkip: { print("Skip") }
    )
}

