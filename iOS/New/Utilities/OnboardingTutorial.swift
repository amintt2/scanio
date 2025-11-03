//
//  OnboardingTutorial.swift
//  Aidoku (iOS)
//
//  Created for onboarding tutorial system
//

import Foundation
import SwiftUI

// MARK: - Onboarding Step Model
struct OnboardingStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let targetView: OnboardingTarget
    let tooltipPosition: TooltipPosition
}

enum OnboardingTarget {
    case browseTab
    case addSourceButton
    case libraryTab
    case historyTab
    case settingsTab
    case profileSection
}

enum TooltipPosition {
    case top
    case bottom
    case leading
    case trailing
    case center
}

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var isActive: Bool = false
    @Published var currentStep: Int = 0
    @Published var hasCompletedTutorial: Bool = false
    @Published var targetFrame: CGRect = .zero

    weak var tabBarController: UITabBarController?
    var onStepChanged: (() -> Void)?

    private init() {
        loadState()
    }

    func loadState() {
        hasCompletedTutorial = UserDefaults.standard.bool(forKey: "Onboarding.hasCompletedTutorial")
        isActive = UserDefaults.standard.bool(forKey: "Onboarding.isActive")
        currentStep = UserDefaults.standard.integer(forKey: "Onboarding.currentStep")

        print("🎓 [Onboarding] Loaded state - completed: \(hasCompletedTutorial), active: \(isActive), step: \(currentStep)")
    }

    func startTutorial() {
        print("🎓 [Onboarding] Starting tutorial")
        isActive = true
        currentStep = 0
        hasCompletedTutorial = false
        saveState()
        updateTargetFrame()
    }

    func nextStep() {
        print("🎓 [Onboarding] Moving to next step from \(currentStep)")
        currentStep += 1
        saveState()
        updateTargetFrame()
        onStepChanged?()
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        print("🎓 [Onboarding] Moving to previous step from \(currentStep)")
        currentStep -= 1
        saveState()
        updateTargetFrame()
        onStepChanged?()
    }

    func skipTutorial() {
        print("🎓 [Onboarding] Skipping tutorial")
        isActive = false
        hasCompletedTutorial = true
        currentStep = 0
        saveState()
    }

    func completeTutorial() {
        print("🎓 [Onboarding] Completing tutorial")
        isActive = false
        hasCompletedTutorial = true
        currentStep = 0
        saveState()
    }

    func resetTutorial() {
        print("🎓 [Onboarding] Resetting tutorial")
        isActive = false
        hasCompletedTutorial = false
        currentStep = 0
        saveState()
    }

    func updateTargetFrame() {
        guard let tabBarController = tabBarController else {
            print("🎓 [Onboarding] No tab bar controller set")
            return
        }

        guard currentStep < steps.count else { return }
        let step = steps[currentStep]

        if let frame = getTabBarButtonFrame(for: step.targetView, in: tabBarController) {
            DispatchQueue.main.async {
                self.targetFrame = frame
                print("🎓 [Onboarding] Updated target frame: \(frame)")
            }
        }
    }

    private func getTabBarButtonFrame(for target: OnboardingTarget, in tabBarController: UITabBarController) -> CGRect? {
        let tabBar = tabBarController.tabBar

        // Get the index for the target
        let targetIndex: Int
        switch target {
        case .libraryTab:
            targetIndex = 0
        case .browseTab:
            targetIndex = 1
        case .historyTab:
            targetIndex = 2
        case .settingsTab:
            if #available(iOS 26.0, *) {
                targetIndex = 3
            } else {
                targetIndex = 4
            }
        default:
            return nil
        }

        // Find the actual button view in the tab bar
        // Tab bar buttons are UIControl subviews
        let tabBarButtons = tabBar.subviews
            .filter { $0 is UIControl }
            .sorted { $0.frame.minX < $1.frame.minX }

        guard targetIndex < tabBarButtons.count else {
            print("🎓 [Onboarding] Target index \(targetIndex) out of bounds")
            return nil
        }

        let button = tabBarButtons[targetIndex]
        let frameInWindow = button.convert(button.bounds, to: nil)

        print("🎓 [Onboarding] Found button at index \(targetIndex): \(frameInWindow)")
        return frameInWindow
    }

    private func saveState() {
        UserDefaults.standard.set(hasCompletedTutorial, forKey: "Onboarding.hasCompletedTutorial")
        UserDefaults.standard.set(isActive, forKey: "Onboarding.isActive")
        UserDefaults.standard.set(currentStep, forKey: "Onboarding.currentStep")
    }
    
    // Tutorial steps definition
    let steps: [OnboardingStep] = [
        OnboardingStep(
            id: 1,
            title: "Ajouter des sources",
            description: """
Les sources vous permettent d'accéder à du contenu.

⚠️ Important : Pour respecter les règles de l'App Store, assurez-vous d'utiliser uniquement des sources légales et autorisées.

Vous pouvez trouver des sources dans l'onglet Browse en appuyant sur le bouton '+'.
""",
            targetView: .browseTab,
            tooltipPosition: .top
        ),
        OnboardingStep(
            id: 2,
            title: "Bibliothèque et Historique",
            description: """
📚 Bibliothèque : Vos histoires sauvegardées et organisées par catégories.

🕐 Historique : Retrouvez rapidement vos lectures récentes.

Astuce : Ajoutez des histoires à votre bibliothèque pour les retrouver facilement !
""",
            targetView: .libraryTab,
            tooltipPosition: .top
        ),
        OnboardingStep(
            id: 3,
            title: "Paramètres et Compte",
            description: """
⚙️ Personnalisez votre expérience de lecture dans les Paramètres.

☁️ Créez un compte (optionnel) pour :
• Synchroniser vos données entre appareils
• Sauvegarder votre historique dans le cloud
• Accéder à des fonctionnalités sociales

Vous pouvez créer un compte maintenant ou plus tard !
""",
            targetView: .settingsTab,
            tooltipPosition: .top
        )
    ]
}

