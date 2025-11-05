# 🧪 Guide de Configuration des Tests - TomoScan

Ce guide explique comment configurer et exécuter les tests XCTest pour TomoScan.

---

## 📁 Fichiers de Tests Créés

Les fichiers de tests suivants ont été créés dans le dossier `TomoScanTests/` :

1. **SupabaseManagerTests.swift** - Tests pour SupabaseManager
   - Configuration Supabase
   - Gestion de session
   - Authentification
   - Refresh de session

2. **UserProfileTests.swift** - Tests pour les modèles de données
   - UserProfile
   - UserStats
   - ReadingStatus
   - PersonalRanking
   - AuthSession

3. **NetworkTests.swift** - Tests réseau et erreurs
   - Reachability
   - ErrorManager
   - UserFacingError
   - Retry logic

4. **Info.plist** - Configuration du bundle de tests

---

## 🔧 Configuration du Target de Tests dans Xcode

### Méthode 1: Ajouter le Target Manuellement (Recommandé)

1. **Ouvrir Xcode**
   ```bash
   open Aidoku.xcodeproj
   ```

2. **Créer un nouveau Test Target**
   - Cliquer sur le projet "Aidoku" dans le navigateur
   - Cliquer sur le "+" en bas de la liste des targets
   - Choisir "iOS" → "Unit Testing Bundle"
   - Nom: `TomoScanTests`
   - Target to be Tested: `Aidoku (iOS)`
   - Cliquer "Finish"

3. **Supprimer le fichier de test par défaut**
   - Xcode crée un fichier `TomoScanTestsTests.swift`
   - Le supprimer (Move to Trash)

4. **Ajouter les fichiers de tests existants**
   - Clic droit sur le groupe `TomoScanTests` dans Xcode
   - "Add Files to TomoScanTests..."
   - Sélectionner tous les fichiers `.swift` dans `TomoScanTests/`
   - ✅ Cocher "Copy items if needed"
   - ✅ Cocher "TomoScanTests" dans "Add to targets"
   - Cliquer "Add"

5. **Configurer le Target**
   - Sélectionner le target `TomoScanTests`
   - Onglet "Build Settings"
   - Chercher "Bundle Identifier"
   - Définir: `xyz.skitty.Aidoku.TomoScanTests`

6. **Ajouter les dépendances**
   - Onglet "Build Phases"
   - Développer "Link Binary With Libraries"
   - Cliquer "+" et ajouter:
     - `XCTest.framework`

7. **Configurer l'accès au code source**
   - Onglet "Build Settings"
   - Chercher "Enable Testing Search Paths"
   - Définir à "Yes"

### Méthode 2: Utiliser le Script Automatique

```bash
# Exécuter le script de configuration
./setup_tests.sh
```

---

## ▶️ Exécuter les Tests

### Dans Xcode (Interface Graphique)

1. **Ouvrir le Test Navigator**
   - Cmd + 6 ou cliquer sur l'icône ◇ dans la barre latérale

2. **Exécuter tous les tests**
   - Cliquer sur le bouton ▶ à côté de "TomoScanTests"
   - Ou: Cmd + U

3. **Exécuter un fichier de tests spécifique**
   - Cliquer sur ▶ à côté du nom du fichier
   - Ex: "SupabaseManagerTests"

4. **Exécuter un test individuel**
   - Cliquer sur ▶ à côté du nom de la fonction
   - Ex: "testSupabaseManagerInitialization"

### En Ligne de Commande

```bash
# Exécuter tous les tests
xcodebuild test \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -skipPackagePluginValidation

# Exécuter un fichier de tests spécifique
xcodebuild test \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -only-testing:TomoScanTests/SupabaseManagerTests \
  -skipPackagePluginValidation

# Exécuter un test spécifique
xcodebuild test \
  -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -only-testing:TomoScanTests/SupabaseManagerTests/testSupabaseManagerInitialization \
  -skipPackagePluginValidation
```

---

## 📊 Liste des Tests

### SupabaseManagerTests (9 tests)

| Test | Description |
|------|-------------|
| `testSupabaseManagerInitialization` | Vérifie que SupabaseManager s'initialise |
| `testSupabaseURLIsValid` | Vérifie que l'URL Supabase est valide |
| `testSupabaseAnonKeyExists` | Vérifie que la clé anon existe |
| `testSessionPersistence` | Vérifie la sauvegarde de session |
| `testClearSession` | Vérifie l'effacement de session |
| `testIsAuthenticatedWithValidSession` | Vérifie l'auth avec session valide |
| `testIsAuthenticatedWithExpiredSession` | Vérifie l'auth avec session expirée |
| `testSessionRefreshLogic` | Vérifie la logique de refresh |
| `testSupabaseErrorTypes` | Vérifie les types d'erreur |

### UserProfileTests (10 tests)

| Test | Description |
|------|-------------|
| `testUserProfileDecoding` | Décodage UserProfile depuis JSON |
| `testUserProfileEncoding` | Encodage UserProfile vers JSON |
| `testUserStatsDecoding` | Décodage UserStats depuis JSON |
| `testUserStatsDefaultValues` | Valeurs par défaut UserStats |
| `testReadingStatusValues` | Valeurs ReadingStatus |
| `testReadingStatusRawValues` | Raw values ReadingStatus |
| `testPersonalRankingDecoding` | Décodage PersonalRanking |
| `testAuthSessionExpiresAtIsSaved` | expiresAt est sauvegardé |
| `testAuthSessionWithoutExpiresAt` | expiresAt calculé si absent |

### NetworkTests (13 tests)

| Test | Description |
|------|-------------|
| `testReachabilityExists` | Vérifie que Reachability fonctionne |
| `testNetworkDataTypeValues` | Vérifie les types de réseau |
| `testErrorManagerSingleton` | Vérifie le singleton ErrorManager |
| `testErrorManagerInitialState` | État initial ErrorManager |
| `testErrorManagerHandleError` | Gestion d'erreur |
| `testErrorManagerClearError` | Effacement d'erreur |
| `testUserFacingErrorFromNetworkError` | Erreur réseau formatée |
| `testUserFacingErrorFromAuthError` | Erreur auth formatée |
| `testUserFacingErrorFromInvalidResponse` | Erreur serveur formatée |
| `testUserFacingErrorFromDecodingError` | Erreur décodage formatée |
| `testUserFacingErrorHasUniqueID` | ID unique pour chaque erreur |
| `testRetryLogicWithSuccess` | Retry réussit après échec |
| `testRetryLogicWithAuthError` | Pas de retry pour auth |
| `testRetryLogicMaxAttempts` | Nombre max de tentatives |

**Total: 32 tests**

---

## ✅ Résultats Attendus

Après configuration, tous les tests devraient passer :

```
Test Suite 'All tests' started
Test Suite 'TomoScanTests.xctest' started
Test Suite 'SupabaseManagerTests' started
  ✓ testSupabaseManagerInitialization (0.001s)
  ✓ testSupabaseURLIsValid (0.001s)
  ✓ testSupabaseAnonKeyExists (0.001s)
  ✓ testSessionPersistence (0.002s)
  ✓ testClearSession (0.001s)
  ✓ testIsAuthenticatedWithValidSession (0.001s)
  ✓ testIsAuthenticatedWithExpiredSession (0.001s)
  ✓ testSessionRefreshLogic (0.001s)
  ✓ testSupabaseErrorTypes (0.001s)
Test Suite 'SupabaseManagerTests' passed (0.010s)

Test Suite 'UserProfileTests' started
  ✓ testUserProfileDecoding (0.002s)
  ✓ testUserProfileEncoding (0.001s)
  ✓ testUserStatsDecoding (0.001s)
  ✓ testUserStatsDefaultValues (0.001s)
  ✓ testReadingStatusValues (0.001s)
  ✓ testReadingStatusRawValues (0.001s)
  ✓ testPersonalRankingDecoding (0.001s)
  ✓ testAuthSessionExpiresAtIsSaved (0.102s)
  ✓ testAuthSessionWithoutExpiresAt (0.001s)
Test Suite 'UserProfileTests' passed (0.111s)

Test Suite 'NetworkTests' started
  ✓ testReachabilityExists (0.001s)
  ✓ testNetworkDataTypeValues (0.001s)
  ✓ testErrorManagerSingleton (0.001s)
  ✓ testErrorManagerInitialState (0.101s)
  ✓ testErrorManagerHandleError (1.002s)
  ✓ testErrorManagerClearError (1.001s)
  ✓ testUserFacingErrorFromNetworkError (0.001s)
  ✓ testUserFacingErrorFromAuthError (0.001s)
  ✓ testUserFacingErrorFromInvalidResponse (0.001s)
  ✓ testUserFacingErrorFromDecodingError (0.001s)
  ✓ testUserFacingErrorHasUniqueID (0.001s)
  ✓ testRetryLogicWithSuccess (0.102s)
  ✓ testRetryLogicWithAuthError (0.001s)
  ✓ testRetryLogicMaxAttempts (0.201s)
Test Suite 'NetworkTests' passed (2.415s)

Test Suite 'TomoScanTests.xctest' passed (2.536s)
Test Suite 'All tests' passed (2.537s)

Executed 32 tests, with 0 failures (0 unexpected) in 2.537s
```

---

## 🐛 Dépannage

### Erreur: "No such module 'Aidoku'"

**Solution**: Vérifier que le target de tests a accès au code source
1. Sélectionner le target `TomoScanTests`
2. Build Settings → "Enable Testing Search Paths" → Yes
3. Build Settings → "Defines Module" → Yes (pour le target Aidoku)

### Erreur: "Use of unresolved identifier"

**Solution**: Ajouter `@testable import Aidoku` en haut des fichiers de tests

### Tests ne s'affichent pas dans le Test Navigator

**Solution**: 
1. Product → Clean Build Folder (Cmd + Shift + K)
2. Fermer et rouvrir Xcode
3. Rebuild le projet (Cmd + B)

### Erreur de compilation dans les tests

**Solution**: Vérifier que tous les fichiers sources nécessaires sont compilés
1. Target Aidoku (iOS) → Build Phases → Compile Sources
2. Vérifier que tous les fichiers .swift sont listés

---

## 📝 Ajouter de Nouveaux Tests

### 1. Créer un nouveau fichier de tests

```swift
//
//  MyNewTests.swift
//  TomoScanTests
//

import XCTest
@testable import Aidoku

final class MyNewTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Setup avant chaque test
    }
    
    override func tearDownWithError() throws {
        // Cleanup après chaque test
        try super.tearDownWithError()
    }
    
    func testExample() {
        // Arrange
        let value = 42
        
        // Act
        let result = value * 2
        
        // Assert
        XCTAssertEqual(result, 84)
    }
}
```

### 2. Ajouter le fichier au target

- Clic droit sur `TomoScanTests` dans Xcode
- "Add Files to TomoScanTests..."
- Sélectionner le nouveau fichier
- ✅ Cocher "TomoScanTests" dans "Add to targets"

### 3. Exécuter les nouveaux tests

- Cmd + U pour tout exécuter
- Ou cliquer sur ▶ à côté du nouveau test

---

## 🎯 Bonnes Pratiques

1. **Nommer les tests clairement**
   - `test` + `WhatIsBeingTested` + `ExpectedBehavior`
   - Ex: `testUserProfile_WhenDecoded_ShouldHaveCorrectValues`

2. **Utiliser Arrange-Act-Assert**
   ```swift
   func testExample() {
       // Arrange - Préparer les données
       let input = "test"
       
       // Act - Exécuter l'action
       let result = input.uppercased()
       
       // Assert - Vérifier le résultat
       XCTAssertEqual(result, "TEST")
   }
   ```

3. **Tester un seul comportement par test**
   - Éviter les tests qui testent plusieurs choses
   - Créer plusieurs petits tests plutôt qu'un gros

4. **Utiliser les expectations pour l'async**
   ```swift
   func testAsync() async throws {
       let result = try await someAsyncFunction()
       XCTAssertNotNil(result)
   }
   ```

5. **Nettoyer après les tests**
   - Utiliser `tearDownWithError()` pour cleanup
   - Réinitialiser les singletons si nécessaire

---

## 📚 Ressources

- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [Swift Testing Best Practices](https://www.swiftbysundell.com/basics/unit-testing/)

---

**Les tests sont maintenant configurés ! 🎉**

Exécutez `Cmd + U` dans Xcode pour lancer tous les tests.

