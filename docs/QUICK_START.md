# 🚀 TomoScan - Quick Start Guide

Guide rapide pour travailler sur le projet TomoScan.

---

## 📦 Installation

```bash
# 1. Cloner le projet
git clone https://github.com/amintt2/scanio.git
cd scanio

# 2. Ouvrir dans Xcode
open Aidoku.xcodeproj

# 3. Sélectionner le scheme "Aidoku (iOS)"
# 4. Sélectionner un simulateur (iPhone 15)
# 5. Build : Cmd + B
# 6. Run : Cmd + R
```

---

## 🏗️ Build Commands

### Build iOS (Simulator)
```bash
xcodebuild \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  build
```

### Build macOS
```bash
xcodebuild \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (macOS)" \
  -configuration Debug \
  build
```

### Run Tests
```bash
# Configurer les tests (première fois)
./scripts/setup_tests.sh

# Exécuter les tests
xcodebuild test \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Ou dans Xcode : Cmd + U
```

### Clean Build
```bash
# Via terminal
xcodebuild clean \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)"

# Ou dans Xcode : Cmd + Shift + K
```

---

## 📁 Structure du Projet

```
scanio/
├── iOS/                    # Code spécifique iOS
│   ├── UI/                # Vues UIKit (legacy)
│   └── New/Views/         # Vues SwiftUI (nouvelles)
├── macOS/                 # Code spécifique macOS
├── Shared/                # Code partagé iOS/macOS
│   ├── Managers/          # Logique métier
│   ├── Models/            # Modèles de données
│   ├── Data/              # CoreData
│   └── Sources/           # Sources WASM
├── TomoScanTests/         # Tests unitaires
├── docs/                  # Documentation
│   ├── debugging/         # Guides de debug
│   ├── features/          # Spécifications features
│   ├── onboarding/        # Guides onboarding
│   └── tests/             # Documentation tests
├── bdd/                   # Scripts SQL Supabase
└── scripts/               # Scripts utilitaires
```

---

## 🔧 Fichiers Clés

### Configuration
- `Shared/Managers/SupabaseConfig.swift` - Config Supabase
- `iOS/SceneDelegate.swift` - Point d'entrée iOS
- `Shared/Assets.xcassets/` - Assets (couleurs, images)

### Managers (Logique Métier)
- `Shared/Managers/SupabaseManager.swift` - API Supabase
- `Shared/Managers/SyncManager.swift` - Synchronisation
- `Shared/Managers/DownloadManager.swift` - Téléchargements
- `Shared/Managers/HistoryManager.swift` - Historique de lecture
- `Shared/Managers/ErrorManager.swift` - Gestion d'erreurs

### Navigation
- `iOS/UI/Common/TabBarController.swift` - Navigation principale
- `iOS/New/Views/Settings/Settings.swift` - Page Settings

### Reader
- `iOS/UI/Reader/ReaderViewController.swift` - Lecteur principal
- `iOS/UI/Reader/Readers/Paged/` - Lecteur paginé
- `iOS/UI/Reader/Readers/Webtoon/` - Lecteur webtoon

---

## 🐛 Debugging

### Logs Importants

```swift
// Dans le code
print("🔵 Info message")
print("✅ Success message")
print("❌ Error message")
print("🔄 Sync message")
```

### Filtrer les Logs dans Xcode

```
1. Ouvrir la console : Cmd + Shift + Y
2. Dans la barre de recherche, taper :
   - "✅" pour voir les succès
   - "❌" pour voir les erreurs
   - "🔄" pour voir les syncs
```

### Problèmes Courants

**Build Failed - "Cannot find 'ErrorManager'"**
```bash
./scripts/add_error_manager.sh
```

**Build Failed - "No such module 'AidokuRunner'"**
```
Xcode > Product > Clean Build Folder (Cmd + Shift + K)
Puis rebuild : Cmd + B
```

**Sync Failed - "networkError"**
```bash
# Vérifier la config Supabase
cat Shared/Managers/SupabaseConfig.swift

# Tester la connexion
curl https://supabase.mciut.fr/rest/v1/ \
  -H "apikey: VOTRE_ANON_KEY"
```

---

## 📝 Conventions de Code

### Commits
```bash
# Format : type(scope): description

git commit -m "fix(sync): correct library upload to Supabase"
git commit -m "feat(discover): add discover page"
git commit -m "refactor(profile): move profile out of settings"
git commit -m "test(sync): add tests for library sync"
```

### Swift Style
- Indentation : 4 espaces
- Accolades : Style K&R (même ligne)
- Nommage : camelCase pour variables, PascalCase pour types

### Tests
```swift
func testFeature_WhenCondition_ShouldExpectedBehavior() async throws {
    // Arrange
    let item = createTestItem()
    
    // Act
    try await performAction(item)
    
    // Assert
    XCTAssertTrue(condition)
}
```

---

## 🎯 Workflow de Développement

### 1. Créer une Branche
```bash
git checkout -b feature/nom-de-la-feature
```

### 2. Faire les Modifications
```bash
# Éditer les fichiers
# Tester localement
```

### 3. Tester
```bash
# Build
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" build

# Tests
xcodebuild test -project Aidoku.xcodeproj -scheme "Aidoku (iOS)"
```

### 4. Commit
```bash
git add .
git commit -m "feat(scope): description"
```

### 5. Push
```bash
git push origin feature/nom-de-la-feature
```

### 6. Créer une PR
```bash
# Sur GitHub
# Créer une Pull Request
# Attendre la review
# Merger
```

---

## 📚 Documentation Complète

Pour plus de détails, voir :

- **[ROADMAP_IMPROVEMENTS.md](features/ROADMAP_IMPROVEMENTS.md)** - Plan complet des améliorations
- **[README.md](../README.md)** - Documentation principale du projet
- **[docs/debugging/](debugging/)** - Guides de debugging
- **[docs/features/](features/)** - Spécifications des features
- **[docs/tests/](tests/)** - Documentation des tests

---

## 🆘 Besoin d'Aide ?

1. Vérifier la documentation dans `docs/`
2. Chercher dans les issues GitHub
3. Demander dans les discussions GitHub
4. Contacter l'équipe

---

**Dernière mise à jour** : 2025-11-06

