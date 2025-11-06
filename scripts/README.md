# 🛠️ Scripts - TomoScan

Scripts utilitaires pour le développement et les tests de TomoScan.

## 📁 Scripts Disponibles

### 🧪 Tests

#### `setup_tests.sh`
Configure le target de tests XCTest dans Xcode.

**Usage** :
```bash
./scripts/setup_tests.sh
```

**Ce qu'il fait** :
- ✅ Vérifie que tous les fichiers de tests existent
- ✅ Affiche les instructions détaillées pour créer le target
- ✅ Propose d'ouvrir Xcode automatiquement
- ✅ Guide l'utilisateur étape par étape

**Prérequis** :
- Xcode installé
- Fichiers de tests dans `TomoScanTests/`

---

#### `run_tests.sh`
Exécute les tests automatisés (vérifications de fichiers et build).

**Usage** :
```bash
./scripts/run_tests.sh
```

**Ce qu'il fait** :
- ✅ Vérifie l'existence des fichiers Swift importants
- ✅ Vérifie l'existence des managers
- ✅ Vérifie l'existence des modèles
- ✅ Compile le projet
- ✅ Affiche un rapport détaillé

**Note** : Ce script ne lance pas les tests XCTest, il vérifie juste que tout est en place.

---

### 🔧 Configuration

#### `add_error_manager.sh`
Guide pour ajouter ErrorManager.swift au projet Xcode.

**Usage** :
```bash
./scripts/add_error_manager.sh
```

**Ce qu'il fait** :
- ✅ Vérifie que ErrorManager.swift existe
- ✅ Affiche les instructions détaillées
- ✅ Propose d'ouvrir Xcode
- ✅ Guide l'ajout du fichier au projet

**Quand l'utiliser** :
- Après avoir créé ErrorManager.swift
- Si le build échoue avec "Cannot find 'ErrorManager' in scope"

---

## 🚀 Démarrage Rapide

### Configuration Initiale

```bash
# 1. Ajouter ErrorManager au projet
./scripts/add_error_manager.sh

# 2. Configurer les tests
./scripts/setup_tests.sh

# 3. Vérifier que tout fonctionne
./scripts/run_tests.sh
```

### Workflow de Développement

```bash
# Avant de commencer à coder
./scripts/run_tests.sh

# Après avoir fait des modifications
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" build

# Pour lancer les tests XCTest (après configuration)
xcodebuild test -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

## 📋 Détails des Scripts

### setup_tests.sh

**Fichiers vérifiés** :
- `TomoScanTests/SupabaseManagerTests.swift`
- `TomoScanTests/UserProfileTests.swift`
- `TomoScanTests/NetworkTests.swift`
- `TomoScanTests/Info.plist`

**Instructions fournies** :
1. Ouvrir Xcode
2. Créer un nouveau target de tests
3. Configurer le Bundle ID
4. Ajouter les fichiers de tests
5. Configurer les Build Settings
6. Exécuter les tests

**Sortie** :
- ✅ Colorisée avec emojis
- ✅ Instructions étape par étape
- ✅ Commandes prêtes à copier-coller

---

### run_tests.sh

**Vérifications effectuées** :
1. **Fichiers Swift** (15 vérifications)
   - AppDelegate.swift
   - SupabaseManager.swift
   - ErrorManager.swift
   - SyncManager.swift
   - etc.

2. **Managers** (5 vérifications)
   - SupabaseManager
   - ErrorManager
   - SyncManager
   - CoreDataManager
   - etc.

3. **Modèles** (3 vérifications)
   - User.swift
   - UserProfile.swift
   - etc.

4. **Build** (1 vérification)
   - Compilation du projet

**Sortie** :
```
╔══════════════════════════════════════════════════════════╗
║              🧪 TESTS AUTOMATISÉS - TomoScan             ║
╚══════════════════════════════════════════════════════════╝

┌──────────────────────────────────────────────────────────┐
│ 📁 Vérification des fichiers                            │
└──────────────────────────────────────────────────────────┘

✅ iOS/AppDelegate.swift
✅ Shared/Managers/SupabaseManager.swift
...

┌──────────────────────────────────────────────────────────┐
│ 📊 RÉSUMÉ                                                │
└──────────────────────────────────────────────────────────┘

Tests réussis: 15/15
Build: SUCCEEDED
```

---

### add_error_manager.sh

**Vérifications** :
- Existence de `Shared/Managers/ErrorManager.swift`

**Instructions** :
1. Ouvrir Xcode
2. Clic droit sur `Shared/Managers`
3. Choisir "Add Files to 'Aidoku'..."
4. Sélectionner `ErrorManager.swift`
5. Cocher les targets (iOS + macOS)
6. Compiler

**Sortie** :
```
╔══════════════════════════════════════════════════════════╗
║          📁 Ajout de ErrorManager.swift au projet        ║
╚══════════════════════════════════════════════════════════╝

✅ ErrorManager.swift trouvé

╔══════════════════════════════════════════════════════════╗
║                  📋 INSTRUCTIONS MANUELLES               ║
╚══════════════════════════════════════════════════════════╝

1. Ouvrir Xcode
   open Aidoku.xcodeproj
...
```

---

## 🔧 Personnalisation

### Modifier les scripts

Tous les scripts sont en bash et peuvent être modifiés :

```bash
# Éditer un script
nano scripts/setup_tests.sh

# Rendre un script exécutable
chmod +x scripts/mon_script.sh

# Tester un script
bash -x scripts/mon_script.sh  # Mode debug
```

### Ajouter un nouveau script

```bash
# Créer le script
touch scripts/mon_nouveau_script.sh

# Rendre exécutable
chmod +x scripts/mon_nouveau_script.sh

# Ajouter le shebang
echo '#!/bin/bash' > scripts/mon_nouveau_script.sh

# Éditer
nano scripts/mon_nouveau_script.sh
```

## 📊 Statut des Scripts

| Script | Statut | Dernière MAJ |
|--------|--------|--------------|
| `setup_tests.sh` | ✅ Fonctionnel | 2025-11-05 |
| `run_tests.sh` | ✅ Fonctionnel | 2025-11-05 |
| `add_error_manager.sh` | ✅ Fonctionnel | 2025-11-05 |

## 🐛 Dépannage

### Script ne s'exécute pas

```bash
# Vérifier les permissions
ls -l scripts/mon_script.sh

# Rendre exécutable
chmod +x scripts/mon_script.sh
```

### Erreur "command not found"

```bash
# Exécuter depuis la racine du projet
cd /Users/tahar/Documents/scanio
./scripts/mon_script.sh

# Ou avec le chemin complet
bash scripts/mon_script.sh
```

### Erreur "No such file or directory"

```bash
# Vérifier que vous êtes dans le bon dossier
pwd

# Devrait afficher: /Users/tahar/Documents/scanio
```

## 🔗 Liens Utiles

- [Documentation des tests](../docs/tests/TESTS_SETUP_GUIDE.md)
- [Documentation de débogage](../docs/debugging/)
- [README principal](../README.md)

---

**Dernière mise à jour** : 2025-11-06  
**Version** : 1.0

