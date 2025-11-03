# 📋 Plan de développement - Système de Tutoriel Onboarding

## 🎯 Objectif
Créer un système de tutoriel interactif pour guider les nouveaux utilisateurs à travers les fonctionnalités principales de l'application : ajout de sources, historique/bibliothèque, et paramètres/compte cloud.

---

## ⚠️ IMPORTANT - Instructions pour les IA

### Workflow de développement
1. **Lire TOUT ce document avant de commencer**
2. **Travailler sur UNE tâche à la fois** (ne pas sauter d'étapes)
3. **Après CHAQUE modification de code**, lancer cette commande pour vérifier la compilation :
   ```bash
   xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" -configuration Debug -sdk iphonesimulator -skipPackagePluginValidation build 2>&1 | grep -E "(\*\* BUILD)" | tail -1
   ```
4. **Si BUILD FAILED**, corriger les erreurs avant de continuer
5. **Si BUILD SUCCEEDED**, demander à l'utilisateur de tester et donner son feedback
6. **Ne passer à la tâche suivante qu'après validation de l'utilisateur**

### Règles de code
- ✅ **TOUJOURS** utiliser `codebase-retrieval` avant de modifier du code
- ✅ **TOUJOURS** utiliser `str-replace-editor` pour modifier les fichiers existants (JAMAIS réécrire un fichier entier)
- ✅ **TOUJOURS** respecter l'architecture existante (SwiftUI + UIKit hybride)
- ✅ **TOUJOURS** ajouter des logs de debug avec des emojis pour faciliter le débogage
- ❌ **JAMAIS** créer de nouveaux fichiers sans demander confirmation
- ❌ **JAMAIS** modifier plus de 150 lignes à la fois dans un fichier

---

## 📐 Architecture du système de tutoriel

### Concept visuel
- **Overlay sombre** : Assombrir tout l'écran (opacity 0.7-0.8)
- **Spotlight** : Mettre en lumière uniquement l'élément sur lequel l'utilisateur doit cliquer
- **Tooltip** : Bulle d'explication avec flèche pointant vers l'élément
- **Navigation** : Boutons "Suivant", "Précédent", "Passer" (Skip)
- **Progression** : Indicateur de progression (étape X/3)

### Étapes du tutoriel
1. **Étape 0** : Page d'introduction avec bouton "Commencer le tutoriel" et "Passer"
2. **Étape 1** : Présentation des sources (onglet Browse)
   - Expliquer comment ajouter des sources
   - Où trouver des sources légales
   - Avertissement App Store (rester méticuleux sur la légalité)
3. **Étape 2** : Présentation de l'historique et de la bibliothèque
   - Onglet Library : bibliothèque de mangas
   - Onglet History : historique de lecture
4. **Étape 3** : Présentation des paramètres et création de compte
   - Onglet Settings
   - Option de création de compte pour sync cloud (optionnel)

### Stockage de l'état
- **UserDefaults** :
  - `"Onboarding.hasCompletedTutorial"` : Bool (true si tutoriel terminé)
  - `"Onboarding.currentStep"` : Int (étape actuelle, 0-3)
  - `"Onboarding.isActive"` : Bool (true si tutoriel en cours)

---

## 🏗️ PHASE 1 : Création des composants de base

### Tâche 1.1 : Créer le modèle de données du tutoriel

**Créer le fichier** : `iOS/New/Models/OnboardingTutorial.swift`

**Contenu** :
```swift
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
        currentStep += 1
        saveState()
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
            id: 1,
            title: "Ajouter des sources",
            description: "Découvrez comment ajouter des sources de contenu légales pour lire vos histoires préférées.",
            targetView: .browseTab,
            tooltipPosition: .top
        ),
        OnboardingStep(
            id: 2,
            title: "Bibliothèque et Historique",
            description: "Gérez votre collection et retrouvez facilement vos lectures récentes.",
            targetView: .libraryTab,
            tooltipPosition: .top
        ),
        OnboardingStep(
            id: 3,
            title: "Paramètres et Compte",
            description: "Personnalisez l'application et synchronisez vos données dans le cloud (optionnel).",
            targetView: .settingsTab,
            tooltipPosition: .top
        )
    ]
}
```

**Fichiers à créer** :
- `iOS/New/Models/OnboardingTutorial.swift`

---

### Tâche 1.2 : Créer le composant d'overlay avec spotlight

**Créer le fichier** : `iOS/New/Views/Onboarding/OnboardingOverlayView.swift`

**Contenu** :
```swift
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
        .allowsHitTesting(true)
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
                    Rectangle()
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
                .foregroundColor(.white)
            
            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
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
                .fill(Color(.systemBackground))
                .shadow(radius: 20)
        )
        .padding(.horizontal, 32)
        .position(tooltipPosition)
    }
    
    private var tooltipPosition: CGPoint {
        let screenHeight = UIScreen.main.bounds.height
        
        switch step.tooltipPosition {
        case .top:
            return CGPoint(
                x: UIScreen.main.bounds.midX,
                y: targetFrame.minY - 200
            )
        case .bottom:
            return CGPoint(
                x: UIScreen.main.bounds.midX,
                y: targetFrame.maxY + 200
            )
        case .center:
            return CGPoint(
                x: UIScreen.main.bounds.midX,
                y: screenHeight / 2
            )
        default:
            return CGPoint(
                x: UIScreen.main.bounds.midX,
                y: screenHeight / 2
            )
        }
    }
}
```

**Fichiers à créer** :
- `iOS/New/Views/Onboarding/OnboardingOverlayView.swift`

---

## 🎬 PHASE 2 : Page d'introduction

### Tâche 2.1 : Créer la page d'introduction du tutoriel

**Créer le fichier** : `iOS/New/Views/Onboarding/OnboardingWelcomeView.swift`

**Contenu** :
```swift
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
```

**Fichiers à créer** :
- `iOS/New/Views/Onboarding/OnboardingWelcomeView.swift`

---

## 📱 PHASE 3 : Intégration dans TabBarController

### Tâche 3.1 : Détecter le premier lancement et afficher le tutoriel

**Objectif** : Modifier `TabBarController` pour détecter si c'est le premier lancement et afficher la page d'introduction

**Solution** :
1. Dans `iOS/UI/Common/TabBarController.swift`, ajouter :
   ```swift
   private var onboardingHostingController: UIHostingController<OnboardingWelcomeView>?

   override func viewDidAppear(_ animated: Bool) {
       super.viewDidAppear(animated)

       // Check if this is first launch
       if !OnboardingManager.shared.hasCompletedTutorial {
           showOnboardingWelcome()
       }
   }

   private func showOnboardingWelcome() {
       let welcomeView = OnboardingWelcomeView(
           onStart: { [weak self] in
               self?.onboardingHostingController?.dismiss(animated: true) {
                   OnboardingManager.shared.startTutorial()
                   self?.showOnboardingOverlay()
               }
           },
           onSkip: { [weak self] in
               self?.onboardingHostingController?.dismiss(animated: true)
               OnboardingManager.shared.skipTutorial()
           }
       )

       onboardingHostingController = UIHostingController(rootView: welcomeView)
       onboardingHostingController?.modalPresentationStyle = .fullScreen

       if let controller = onboardingHostingController {
           present(controller, animated: true)
       }
   }
   ```

**Fichiers à modifier** :
- `iOS/UI/Common/TabBarController.swift`

---

### Tâche 3.2 : Implémenter le système d'overlay avec spotlight

**Objectif** : Afficher l'overlay avec spotlight sur les éléments ciblés pendant le tutoriel

**Solution** :
1. Créer une extension de `UIView` pour obtenir le frame global :
   ```swift
   extension UIView {
       var globalFrame: CGRect? {
           return superview?.convert(frame, to: nil)
       }
   }
   ```
2. Dans `TabBarController`, ajouter la méthode pour afficher l'overlay :
   ```swift
   private var overlayHostingController: UIHostingController<OnboardingOverlayView>?

   private func showOnboardingOverlay() {
       guard OnboardingManager.shared.isActive else { return }

       let currentStep = OnboardingManager.shared.currentStep
       guard currentStep < OnboardingManager.shared.steps.count else {
           OnboardingManager.shared.completeTutorial()
           return
       }

       let step = OnboardingManager.shared.steps[currentStep]
       let targetFrame = getTargetFrame(for: step.targetView)

       let overlayView = OnboardingOverlayView(
           targetFrame: .constant(targetFrame),
           step: step,
           onNext: { [weak self] in
               if currentStep == OnboardingManager.shared.steps.count - 1 {
                   self?.hideOnboardingOverlay()
                   OnboardingManager.shared.completeTutorial()
               } else {
                   OnboardingManager.shared.nextStep()
                   self?.updateOnboardingOverlay()
               }
           },
           onPrevious: { [weak self] in
               OnboardingManager.shared.previousStep()
               self?.updateOnboardingOverlay()
           },
           onSkip: { [weak self] in
               self?.hideOnboardingOverlay()
               OnboardingManager.shared.skipTutorial()
           }
       )

       overlayHostingController = UIHostingController(rootView: overlayView)
       overlayHostingController?.view.backgroundColor = .clear
       overlayHostingController?.modalPresentationStyle = .overFullScreen

       if let controller = overlayHostingController {
           present(controller, animated: true)
       }
   }

   private func getTargetFrame(for target: OnboardingTarget) -> CGRect? {
       switch target {
       case .browseTab:
           return tabBar.items?[1].value(forKey: "view") as? UIView
               .flatMap { $0.globalFrame }
       case .libraryTab:
           return tabBar.items?[0].value(forKey: "view") as? UIView
               .flatMap { $0.globalFrame }
       case .historyTab:
           return tabBar.items?[2].value(forKey: "view") as? UIView
               .flatMap { $0.globalFrame }
       case .settingsTab:
           return tabBar.items?[4].value(forKey: "view") as? UIView
               .flatMap { $0.globalFrame }
       default:
           return nil
       }
   }

   private func updateOnboardingOverlay() {
       hideOnboardingOverlay()
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
           self?.showOnboardingOverlay()
       }
   }

   private func hideOnboardingOverlay() {
       overlayHostingController?.dismiss(animated: true)
       overlayHostingController = nil
   }
   ```

**Fichiers à modifier** :
- `iOS/UI/Common/TabBarController.swift`

---

### Tâche 3.3 : Ajouter un bouton "Revoir le tutoriel" dans Settings

**Objectif** : Permettre aux utilisateurs de relancer le tutoriel depuis les paramètres

**Solution** :
1. Modifier `iOS/New/Views/Settings/Settings.swift` pour ajouter une nouvelle section :
   ```swift
   private static let helpSettings: [Setting] = [
       .init(value: .group(.init(items: [
           .init(
               key: "Help.restartTutorial",
               title: "Revoir le tutoriel",
               value: .button(.init(
                   destructive: false,
                   action: {
                       OnboardingManager.shared.resetTutorial()
                       OnboardingManager.shared.startTutorial()
                       // Notify TabBarController to show tutorial
                       NotificationCenter.default.post(
                           name: NSNotification.Name("RestartOnboarding"),
                           object: nil
                       )
                   }
               ))
           )
       ])))
   ]
   ```
2. Ajouter cette section dans la liste principale des settings
3. Dans `TabBarController`, observer la notification :
   ```swift
   override func viewDidLoad() {
       super.viewDidLoad()

       // ... existing code ...

       NotificationCenter.default.addObserver(
           self,
           selector: #selector(handleRestartOnboarding),
           name: NSNotification.Name("RestartOnboarding"),
           object: nil
       )
   }

   @objc private func handleRestartOnboarding() {
       // Dismiss settings if open
       dismiss(animated: true) { [weak self] in
           self?.showOnboardingWelcome()
       }
   }
   ```

**Fichiers à modifier** :
- `iOS/New/Views/Settings/Settings.swift`
- `iOS/UI/Common/TabBarController.swift`

---

## 🎨 PHASE 4 : Contenu détaillé des étapes

### Tâche 4.1 : Étape 1 - Présentation des sources (Browse)

**Objectif** : Expliquer comment ajouter des sources et où les trouver

**Contenu du tooltip** :
```swift
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
)
```

**Actions supplémentaires** :
- Après avoir cliqué sur "Suivant", naviguer automatiquement vers l'onglet Browse
- Mettre en surbrillance le bouton d'ajout de source

**Fichiers à modifier** :
- `iOS/New/Models/OnboardingTutorial.swift` (mettre à jour le contenu de l'étape)

---

### Tâche 4.2 : Étape 2 - Bibliothèque et Historique

**Objectif** : Expliquer la différence entre Library et History

**Contenu du tooltip** :
```swift
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
)
```

**Actions supplémentaires** :
- Afficher deux spotlights : un sur Library, un sur History
- Animation pour montrer la différence entre les deux onglets

**Fichiers à modifier** :
- `iOS/New/Models/OnboardingTutorial.swift`
- `iOS/New/Views/Onboarding/OnboardingOverlayView.swift` (support multi-spotlight)

---

### Tâche 4.3 : Étape 3 - Paramètres et Compte Cloud

**Objectif** : Présenter les paramètres et l'option de création de compte

**Contenu du tooltip** :
```swift
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
```

**Actions supplémentaires** :
- Après "Terminer", proposer optionnellement de créer un compte
- Afficher un bouton "Créer un compte" et "Plus tard"

**Fichiers à modifier** :
- `iOS/New/Models/OnboardingTutorial.swift`
- `iOS/New/Views/Onboarding/OnboardingOverlayView.swift`

---

## 🔧 PHASE 5 : Améliorations et polish

### Tâche 5.1 : Ajouter des animations fluides

**Objectif** : Rendre les transitions entre étapes plus fluides

**Solution** :
1. Ajouter des animations de fade in/out pour l'overlay
2. Animer le déplacement du spotlight d'un élément à l'autre
3. Ajouter une animation de "pulse" sur l'élément ciblé

**Fichiers à modifier** :
- `iOS/New/Views/Onboarding/OnboardingOverlayView.swift`

---

### Tâche 5.2 : Gérer les cas edge

**Objectif** : Gérer les cas où l'utilisateur interagit avec l'app pendant le tutoriel

**Cas à gérer** :
1. L'utilisateur change d'onglet manuellement → Adapter le tutoriel
2. L'utilisateur met l'app en arrière-plan → Sauvegarder l'état
3. L'utilisateur force-quit l'app → Reprendre au même endroit au prochain lancement

**Solution** :
1. Observer les changements d'onglet dans `TabBarController`
2. Sauvegarder l'état dans `applicationDidEnterBackground`
3. Restaurer l'état dans `applicationWillEnterForeground`

**Fichiers à modifier** :
- `iOS/UI/Common/TabBarController.swift`
- `iOS/AppDelegate.swift`

---

### Tâche 5.3 : Ajouter des analytics (optionnel)

**Objectif** : Tracker l'utilisation du tutoriel pour améliorer l'onboarding

**Métriques à tracker** :
- Nombre d'utilisateurs qui commencent le tutoriel
- Nombre d'utilisateurs qui le terminent
- Nombre d'utilisateurs qui le skip
- Étape où les utilisateurs abandonnent le plus

**Solution** :
1. Ajouter des logs dans `OnboardingManager`
2. Envoyer des événements à un service d'analytics (si disponible)

**Fichiers à modifier** :
- `iOS/New/Models/OnboardingTutorial.swift`

---

## ✅ Checklist finale

Après avoir terminé TOUTES les tâches, vérifier :

### Fonctionnalités de base
- [ ] Le tutoriel s'affiche automatiquement au premier lancement
- [ ] L'overlay sombre fonctionne correctement avec opacity 0.75
- [ ] Le spotlight met bien en lumière l'élément ciblé avec un padding de 16px
- [ ] Les tooltips s'affichent au bon endroit selon la position définie
- [ ] La navigation entre les étapes fonctionne (Suivant/Précédent)
- [ ] Le bouton "Passer" fonctionne et marque le tutoriel comme terminé
- [ ] Le bouton "Terminer" à la dernière étape complète le tutoriel
- [ ] Le bouton "Revoir le tutoriel" dans Settings fonctionne
- [ ] L'état du tutoriel est bien sauvegardé dans UserDefaults

### Interface utilisateur
- [ ] L'indicateur de progression (dots) s'affiche correctement
- [ ] Les animations de transition sont fluides
- [ ] Le texte est lisible sur tous les fonds
- [ ] Les boutons sont accessibles et bien dimensionnés
- [ ] L'interface s'adapte aux différentes tailles d'écran (iPhone/iPad)
- [ ] Le mode sombre est supporté
- [ ] Les animations ne causent pas de lag

### Cas edge
- [ ] Le tutoriel se comporte correctement si l'utilisateur change d'onglet manuellement
- [ ] L'état est sauvegardé si l'app passe en arrière-plan
- [ ] Le tutoriel reprend au bon endroit après un force-quit
- [ ] Le tutoriel ne se réaffiche pas après avoir été complété
- [ ] Le tutoriel peut être relancé depuis les Settings

### Technique
- [ ] Aucune erreur de compilation
- [ ] Aucun warning dans la console
- [ ] Les logs de debug sont présents et informatifs
- [ ] Le code respecte l'architecture existante
- [ ] Les fichiers sont bien organisés dans les bons dossiers

### Contenu
- [ ] Le texte de l'étape 1 mentionne bien les sources légales (App Store compliance)
- [ ] Le texte de l'étape 2 explique clairement la différence Library/History
- [ ] Le texte de l'étape 3 précise que le compte cloud est optionnel
- [ ] Tous les textes sont en français correct
- [ ] Les icônes utilisées sont appropriées

---

## 🚀 Commande de test après chaque modification

```bash
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" -configuration Debug -sdk iphonesimulator -skipPackagePluginValidation build 2>&1 | grep -E "(\*\* BUILD)" | tail -1
```

**Si BUILD SUCCEEDED** → Demander à l'utilisateur de tester et donner son feedback

**Si BUILD FAILED** → Corriger les erreurs avant de continuer

---

## 🎯 Ordre de priorité

1. **PHASE 1** (Composants de base) - Créer les modèles et composants visuels
   - Tâche 1.1 : Modèle de données
   - Tâche 1.2 : Composant d'overlay
2. **PHASE 2** (Page d'introduction) - Créer l'écran de bienvenue
   - Tâche 2.1 : Page d'introduction
3. **PHASE 3** (Intégration) - Intégrer dans l'app
   - Tâche 3.1 : Détection premier lancement
   - Tâche 3.2 : Système d'overlay
   - Tâche 3.3 : Bouton dans Settings
4. **PHASE 4** (Contenu) - Détailler les étapes
   - Tâche 4.1 : Étape Sources
   - Tâche 4.2 : Étape Library/History
   - Tâche 4.3 : Étape Settings/Account
5. **PHASE 5** (Polish) - Améliorations finales
   - Tâche 5.1 : Animations
   - Tâche 5.2 : Cas edge
   - Tâche 5.3 : Analytics (optionnel)

---

## 📝 Notes importantes pour les IA

### Considérations App Store
1. **Légalité des sources** : Le texte de l'étape 1 DOIT mentionner explicitement que seules les sources légales doivent être utilisées
2. **Pas de promotion de piratage** : Ne jamais suggérer ou lister des sources illégales
3. **Clarté sur le contenu** : Expliquer que l'app est un lecteur, pas une source de contenu

### Architecture technique
1. **SwiftUI + UIKit hybride** : L'app utilise les deux frameworks
2. **UserDefaults** : Utilisé pour stocker l'état du tutoriel (simple et efficace)
3. **ObservableObject** : `OnboardingManager` utilise Combine pour la réactivité
4. **Hosting Controllers** : Pour intégrer SwiftUI dans UIKit

### Bonnes pratiques
1. **Logs de debug** : Toujours ajouter des logs avec emoji pour faciliter le débogage
2. **État sauvegardé** : Sauvegarder l'état à chaque changement, pas seulement à la fin
3. **Animations** : Utiliser `withAnimation` pour les transitions SwiftUI
4. **Accessibilité** : Penser aux utilisateurs avec VoiceOver (à implémenter plus tard)

### Améliorations futures (hors scope actuel)
- [ ] Support de VoiceOver pour l'accessibilité
- [ ] Traduction en plusieurs langues
- [ ] Tutoriels contextuels (in-app tips)
- [ ] Vidéos explicatives
- [ ] Gamification (badges pour avoir complété le tutoriel)

---

## 🐛 Problèmes connus et solutions

### Problème 1 : Le spotlight ne s'affiche pas correctement
**Cause** : Le frame de l'élément ciblé n'est pas calculé correctement
**Solution** : Utiliser `convert(_:to:)` pour obtenir le frame dans le système de coordonnées global

### Problème 2 : L'overlay bloque les interactions
**Cause** : `allowsHitTesting(true)` sur tout l'overlay
**Solution** : Utiliser `allowsHitTesting(false)` sur l'overlay sombre, `true` uniquement sur le tooltip

### Problème 3 : Le tutoriel se réaffiche après avoir été complété
**Cause** : `hasCompletedTutorial` n'est pas sauvegardé correctement
**Solution** : Vérifier que `saveState()` est appelé dans `completeTutorial()` et `skipTutorial()`

### Problème 4 : Les animations sont saccadées
**Cause** : Trop de calculs sur le main thread
**Solution** : Pré-calculer les frames et utiliser `DispatchQueue.main.async` pour les mises à jour UI

---

## 📚 Ressources et références

### Documentation Apple
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [UIKit Integration](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable)
- [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### Design inspiration
- [Onboarding UI Patterns](https://www.mobile-patterns.com/onboarding)
- [iOS Human Interface Guidelines - Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)

### Exemples de code similaires dans l'app
- `iOS/New/Views/Settings/ProfileSettingsView.swift` - Utilisation de SwiftUI
- `iOS/UI/Common/TabBarController.swift` - Intégration UIKit
- `iOS/AppDelegate.swift` - UserDefaults registration

---

## 🔄 Workflow de développement recommandé

### Étape par étape
1. **Lire** tout le plan
2. **Créer** les fichiers de modèles (Phase 1.1)
3. **Compiler** et vérifier qu'il n'y a pas d'erreurs
4. **Créer** les composants visuels (Phase 1.2)
5. **Compiler** et tester visuellement dans un preview
6. **Créer** la page d'introduction (Phase 2.1)
7. **Compiler** et tester
8. **Intégrer** dans TabBarController (Phase 3)
9. **Compiler** et tester le flow complet
10. **Affiner** le contenu (Phase 4)
11. **Polir** les animations et cas edge (Phase 5)
12. **Test final** sur device réel

### À chaque étape
1. ✅ Utiliser `codebase-retrieval` pour comprendre le code existant
2. ✅ Faire des modifications incrémentales (max 150 lignes)
3. ✅ Compiler après chaque modification
4. ✅ Tester manuellement
5. ✅ Demander feedback à l'utilisateur
6. ✅ Passer à l'étape suivante uniquement après validation

---

**Bonne chance ! 🚀**

---

## 📞 Support

Si vous rencontrez des problèmes pendant l'implémentation :
1. Vérifier les logs de debug (chercher 🎓 dans la console)
2. Vérifier que UserDefaults contient les bonnes valeurs
3. Vérifier que `OnboardingManager.shared` est bien initialisé
4. Demander à l'utilisateur de tester sur un simulateur propre (reset UserDefaults)

**Commande pour reset UserDefaults** :
```bash
xcrun simctl uninstall booted app.aidoku.Aidoku
```

---

**Fin du document** 🎉

