# 🚀 Guide de Démarrage Rapide - Tutoriel Onboarding

## 📋 Résumé du Projet

Créer un système de tutoriel interactif pour guider les nouveaux utilisateurs à travers 3 étapes :
1. **Sources** : Comment ajouter des sources (avec avertissement légalité)
2. **Bibliothèque/Historique** : Différence entre Library et History
3. **Paramètres/Compte** : Personnalisation et sync cloud (optionnel)

### Caractéristiques visuelles
- ✨ Overlay sombre (opacity 0.75) sur tout l'écran
- 🔦 Spotlight lumineux sur l'élément ciblé
- 💬 Tooltip avec titre, description et boutons de navigation
- 📊 Indicateur de progression (dots)
- 🎯 Bouton "Passer" toujours disponible

---

## 📁 Fichiers à Créer

### Phase 1 : Modèles et Composants
```
iOS/New/Models/
  └── OnboardingTutorial.swift          (OnboardingManager + modèles)

iOS/New/Views/Onboarding/
  ├── OnboardingWelcomeView.swift       (Page d'introduction)
  └── OnboardingOverlayView.swift       (Overlay + Spotlight + Tooltip)
```

### Phase 2 : Modifications
```
iOS/UI/Common/
  └── TabBarController.swift            (Détection premier lancement + affichage)

iOS/New/Views/Settings/
  └── Settings.swift                    (Bouton "Revoir le tutoriel")

iOS/AppDelegate.swift                   (Initialisation UserDefaults)
```

---

## 🎯 Ordre d'Implémentation

### Étape 1 : Créer OnboardingManager
```swift
// iOS/New/Models/OnboardingTutorial.swift
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var isActive: Bool = false
    @Published var currentStep: Int = 0
    @Published var hasCompletedTutorial: Bool = false

    let steps: [OnboardingStep] = [...]

    func startTutorial() { ... }
    func nextStep() { ... }
    func skipTutorial() { ... }
    func completeTutorial() { ... }
}
```

### Étape 2 : Créer les Vues
```swift
// OnboardingWelcomeView.swift
struct OnboardingWelcomeView: View {
    let onStart: () -> Void
    let onSkip: () -> Void
    // Page d'introduction avec icône, texte, features, boutons
}

// OnboardingOverlayView.swift
struct OnboardingOverlayView: View {
    // Overlay sombre + Spotlight + Tooltip
}
```

### Étape 3 : Intégrer dans TabBarController
```swift
// TabBarController.swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if !OnboardingManager.shared.hasCompletedTutorial {
        showOnboardingWelcome()
    }
}

private func showOnboardingWelcome() { ... }
private func showOnboardingOverlay() { ... }
```

### Étape 4 : Ajouter le bouton dans Settings
```swift
// Settings.swift
.init(
    key: "Help.restartTutorial",
    title: "Revoir le tutoriel",
    value: .button(.init(action: {
        OnboardingManager.shared.resetTutorial()
        OnboardingManager.shared.startTutorial()
    }))
)
```

---

## 🔑 UserDefaults Keys

```swift
"Onboarding.hasCompletedTutorial"  // Bool - true si terminé
"Onboarding.isActive"              // Bool - true si en cours
"Onboarding.currentStep"           // Int - étape actuelle (0-2)
```

---

## 🎨 Design Specs

### Overlay
- Couleur : `Color.black.opacity(0.75)`
- Spotlight padding : `16px` autour de l'élément ciblé
- Blend mode : `.destinationOut` pour le cutout

### Tooltip
- Background : `Color(.systemBackground)`
- Corner radius : `16px`
- Shadow : `radius: 20`
- Padding : `24px`
- Horizontal margin : `32px`

### Boutons
- "Commencer" / "Suivant" / "Terminer" : `.borderedProminent`
- "Passer" / "Précédent" : `.bordered`

### Indicateur de progression
- Cercles de `8x8px`
- Actif : `Color.accentColor`
- Inactif : `Color.gray.opacity(0.5)`
- Espacement : `8px`

---

## 📝 Contenu des Étapes

### Étape 1 : Sources
```
Titre : "Ajouter des sources"

Description :
Les sources vous permettent d'accéder à du contenu.

⚠️ Important : Pour respecter les règles de l'App Store,
assurez-vous d'utiliser uniquement des sources légales et autorisées.

Vous pouvez trouver des sources dans l'onglet Browse
en appuyant sur le bouton '+'.

Target : browseTab
Position : top
```

### Étape 2 : Bibliothèque & Historique
```
Titre : "Bibliothèque et Historique"

Description :
📚 Bibliothèque : Vos histoires sauvegardées et organisées par catégories.

🕐 Historique : Retrouvez rapidement vos lectures récentes.

Astuce : Ajoutez des histoires à votre bibliothèque
pour les retrouver facilement !

Target : libraryTab
Position : top
```

### Étape 3 : Paramètres & Compte
```
Titre : "Paramètres et Compte"

Description :
⚙️ Personnalisez votre expérience de lecture dans les Paramètres.

☁️ Créez un compte (optionnel) pour :
• Synchroniser vos données entre appareils
• Sauvegarder votre historique dans le cloud
• Accéder à des fonctionnalités sociales

Vous pouvez créer un compte maintenant ou plus tard !

Target : settingsTab
Position : top
```

---

## ✅ Checklist de Test

### Avant de commencer
- [ ] Lire tout le plan détaillé (`ONBOARDING_TUTORIAL_PLAN.md`)
- [ ] Comprendre l'architecture existante de l'app
- [ ] Vérifier que Xcode compile sans erreur

### Après chaque fichier créé
- [ ] Compiler avec la commande de test
- [ ] Vérifier qu'il n'y a pas d'erreur
- [ ] Vérifier qu'il n'y a pas de warning
- [ ] Demander feedback à l'utilisateur

### Test final
- [ ] Désinstaller l'app du simulateur
- [ ] Réinstaller et lancer (premier lancement)
- [ ] Vérifier que le tutoriel s'affiche
- [ ] Tester le flow complet (Commencer → Étape 1 → 2 → 3 → Terminer)
- [ ] Tester le bouton "Passer"
- [ ] Tester le bouton "Précédent"
- [ ] Relancer l'app → vérifier que le tutoriel ne s'affiche plus
- [ ] Aller dans Settings → "Revoir le tutoriel"
- [ ] Vérifier que le tutoriel se relance

---

## 🐛 Commandes Utiles

### Compiler
```bash
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" -configuration Debug -sdk iphonesimulator -skipPackagePluginValidation build 2>&1 | grep -E "(\*\* BUILD)" | tail -1
```

### Reset UserDefaults (désinstaller l'app)
```bash
xcrun simctl uninstall booted app.aidoku.Aidoku
```

### Voir les logs
```bash
# Dans Xcode Console, filtrer par : 🎓
```

---

## 📞 Besoin d'Aide ?

1. **Consulter le plan détaillé** : `ONBOARDING_TUTORIAL_PLAN.md`
2. **Vérifier les logs** : Chercher 🎓 dans la console
3. **Vérifier UserDefaults** : Utiliser le debugger pour inspecter les valeurs
4. **Demander à l'utilisateur** : En cas de doute, toujours demander

---

## 🎯 Prochaines Étapes

1. ✅ Lire ce guide
2. ✅ Lire le plan détaillé
3. ✅ Commencer par la Phase 1, Tâche 1.1
4. ✅ Compiler après chaque modification
5. ✅ Demander feedback avant de passer à la tâche suivante

---

**Bon courage ! 🚀**
