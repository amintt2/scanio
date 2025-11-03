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
    let targetTab: Int // Tab index to navigate to
    let icon: String
}

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var isActive: Bool = false
    @Published var currentStep: Int = 0
    @Published var hasCompletedTutorial: Bool = false

    weak var tabBarController: UITabBarController?

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
    }

    func nextStep() {
        print("🎓 [Onboarding] Moving to next step from \(currentStep)")
        if currentStep < steps.count - 1 {
            currentStep += 1
            saveState()
        } else {
            completeTutorial()
        }
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        print("🎓 [Onboarding] Moving to previous step from \(currentStep)")
        currentStep -= 1
        saveState()
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



    private func saveState() {
        UserDefaults.standard.set(hasCompletedTutorial, forKey: "Onboarding.hasCompletedTutorial")
        UserDefaults.standard.set(isActive, forKey: "Onboarding.isActive")
        UserDefaults.standard.set(currentStep, forKey: "Onboarding.currentStep")
    }
    
    // Tutorial steps definition
    let steps: [OnboardingStep] = [
        OnboardingStep(
            id: 0,
            title: "Ajouter des sources",
            description: """
C'est ici que vous pouvez ajouter des sources de contenu.

Les sources sont des extensions compatibles Aidoku qui vous permettent d'accéder à différents catalogues de mangas.

⚠️ Important : Utilisez uniquement des sources légales et autorisées pour respecter les règles de l'App Store.

Appuyez sur le bouton '+' en haut à droite pour ajouter une source.
""",
            targetTab: 1, // Browse tab
            icon: "plus.circle.fill"
        ),
        OnboardingStep(
            id: 1,
            title: "Votre Bibliothèque",
            description: """
📚 Ici se trouvent tous vos mangas sauvegardés.

Vous pouvez organiser votre bibliothèque par catégories, trier vos mangas, et suivre votre progression de lecture.

Astuce : Ajoutez des mangas à votre bibliothèque pour les retrouver facilement !
""",
            targetTab: 0, // Library tab
            icon: "books.vertical.fill"
        ),
        OnboardingStep(
            id: 2,
            title: "Historique de lecture",
            description: """
🕐 Retrouvez rapidement vos lectures récentes.

L'historique garde une trace de tous les chapitres que vous avez lus, avec la date et votre progression.

Vous pouvez reprendre votre lecture là où vous l'avez laissée !
""",
            targetTab: 2, // History tab
            icon: "clock.fill"
        ),
        OnboardingStep(
            id: 3,
            title: "Paramètres et Compte",
            description: """
⚙️ Personnalisez votre expérience de lecture.

Vous pouvez modifier :
• Le thème et l'apparence
• Les paramètres de lecture
• Les notifications

☁️ Créez un compte (optionnel) pour synchroniser vos données entre appareils et sauvegarder votre historique dans le cloud.
""",
            targetTab: 4, // Settings tab (index 4 on iOS < 26)
            icon: "gear"
        )
    ]
}

