# 📱 TomoScan

Une application de lecture de manga/manhwa/manhua gratuite et open source pour iOS et macOS, avec profils utilisateur, synchronisation cloud et fonctionnalités sociales.

> **Note**: Ce projet est un fork d'[Aidoku](https://github.com/Aidoku/Aidoku) avec des fonctionnalités étendues de profil utilisateur et de synchronisation Supabase.

## 📖 Documentation

- **[Quick Start Guide](docs/QUICK_START.md)** - Guide rapide pour démarrer
- **[Roadmap & Améliorations](docs/features/ROADMAP_IMPROVEMENTS.md)** - Plan complet des améliorations à venir
- **[Documentation Debugging](docs/debugging/)** - Guides de résolution de problèmes
- **[Documentation Tests](docs/tests/)** - Guide des tests unitaires

## ✨ Fonctionnalités

### 📚 Lecture
- [x] Lecture en ligne via sources externes (WASM)
- [x] Téléchargements pour lecture hors ligne
- [x] Plusieurs modes de lecture (paginé, défilement, vertical, horizontal)
- [x] Upscaling d'images avec CoreML
- [x] Pas de publicités

### 👤 Profil Utilisateur
- [x] Profils utilisateur personnalisables
- [x] Statistiques de lecture détaillées
- [x] Historique de lecture synchronisé
- [x] Bibliothèque personnelle (favoris, en cours, complétés)
- [x] Classements personnels (top mangas)
- [x] Paramètres de visibilité du profil

### 🔄 Synchronisation
- [x] Synchronisation cloud avec Supabase
- [x] Cache local avec CoreData
- [x] Sync automatique en arrière-plan
- [x] Gestion intelligente des conflits

### 🌐 Social
- [x] Commentaires sur les mangas
- [x] Likes sur les commentaires
- [x] Profils publics/privés
- [x] Partage de listes de lecture

### 🔗 Intégrations
- [x] AniList
- [x] MyAnimeList
- [x] Shikimori
- [x] Bangumi

## 🚀 Installation

### Prérequis
- Xcode 15.0+
- iOS 15.0+ / macOS 12.0+
- Compte Supabase (pour les fonctionnalités cloud)

### Configuration

1. **Cloner le repository**
   ```bash
   git clone https://github.com/amintt2/scanio.git
   cd scanio
   ```

2. **Configurer Supabase**

   Créez un fichier `Shared/Managers/SupabaseConfig.swift` :
   ```swift
   import Foundation

   enum SupabaseConfig {
       static let url = "VOTRE_SUPABASE_URL"
       static let anonKey = "VOTRE_SUPABASE_ANON_KEY"
   }
   ```

3. **Importer le schéma de base de données**
   ```bash
   # Voir bdd/README.md pour les instructions détaillées
   psql -h votre-supabase-host -U postgres -d postgres < bdd/supabase_schema.sql
   ```

4. **Ouvrir dans Xcode**
   ```bash
   open Aidoku.xcodeproj
   ```

5. **Build et Run**
   - Sélectionner le scheme "Aidoku (iOS)" ou "Aidoku (macOS)"
   - Appuyer sur `Cmd + R`

## 📁 Structure du Projet

```
scanio/
├── iOS/                    # Code spécifique iOS
│   ├── New/                # Nouvelle UI SwiftUI
│   │   └── Views/          # Vues SwiftUI (Profile, Settings, etc.)
│   └── Old/                # Ancienne UI UIKit
├── macOS/                  # Code spécifique macOS
├── Shared/                 # Code partagé iOS/macOS
│   ├── Managers/           # Gestionnaires (Supabase, CoreData, Sync, Error)
│   ├── Models/             # Modèles de données (User, UserProfile, etc.)
│   ├── Extensions/         # Extensions Swift
│   └── Data/               # CoreData models
├── TomoScanTests/          # Tests unitaires (34 tests XCTest)
│   ├── SupabaseManagerTests.swift
│   ├── UserProfileTests.swift
│   └── NetworkTests.swift
├── docs/                   # Documentation complète
│   ├── debugging/          # Guides de débogage
│   ├── features/           # Spécifications des fonctionnalités
│   ├── onboarding/         # Guides d'onboarding
│   └── tests/              # Documentation des tests
├── bdd/                    # Scripts SQL Supabase
│   ├── supabase_schema.sql
│   ├── supabase_scanio_functions.sql
│   └── ...
└── scripts/                # Scripts utilitaires
    ├── setup_tests.sh
    ├── run_tests.sh
    └── add_error_manager.sh
```

## 🏗️ Architecture

### Frontend
- **SwiftUI** pour les nouvelles vues (Profile, Settings, Rankings)
- **UIKit/Texture** pour les vues existantes (Reader, Browse, Library)
- **Combine** pour la réactivité
- **CoreML** pour l'upscaling d'images

### Backend
- **Supabase** (PostgreSQL + Auth + Realtime)
  - Authentification JWT
  - Base de données PostgreSQL
  - Row Level Security (RLS)
  - Fonctions SQL personnalisées

### Synchronisation
- **CoreData** pour le cache local
- **SyncManager** pour la synchronisation bidirectionnelle
- **Stratégie** : Supabase = source de vérité, CoreData = cache

### Gestion d'Erreurs
- **ErrorManager** pour les erreurs UI
- **Banner non-intrusif** (pas de popups)
- **Retry automatique** (3 tentatives)
- **Logs DEBUG seulement**

## 🧪 Tests

Le projet inclut **34 tests unitaires** couvrant :

### SupabaseManagerTests (9 tests)
- Initialisation et configuration
- Gestion de session (save, load, clear)
- Authentification (valide, expirée)
- Logique de refresh
- Types d'erreur

### UserProfileTests (10 tests)
- Décodage/Encodage des modèles
- Statistiques utilisateur
- Statuts de lecture
- Rankings personnels
- AuthSession (expiresAt sauvegardé)

### NetworkTests (15 tests)
- Reachability
- ErrorManager (singleton, état, gestion)
- UserFacingError (6 types)
- Retry logic (succès, auth, max attempts)

**Exécuter les tests** :
```bash
# Configuration initiale
./scripts/setup_tests.sh

# Dans Xcode
Cmd + U

# En ligne de commande
xcodebuild test -project Aidoku.xcodeproj \
  -scheme "Aidoku (iOS)" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

## 📚 Documentation

### Guides Principaux
- **� [Documentation Complète](docs/README.md)** - Index de toute la documentation
- **🐛 [Guide de Débogage](docs/debugging/)** - Résolution de problèmes
- **✨ [Spécifications des Features](docs/features/)** - Plans détaillés des fonctionnalités
- **🧪 [Guide des Tests](docs/tests/TESTS_SETUP_GUIDE.md)** - Configuration et exécution des tests
- **🗄️ [Documentation BDD](bdd/README.md)** - Schémas et fonctions SQL

### Fonctionnalités Implémentées
Voir [`docs/features/PROFILE_FEATURES_PLAN.md`](docs/features/PROFILE_FEATURES_PLAN.md) pour le plan complet des 6 phases :

1. ✅ **Phase 1** : Modèles de données et schéma Supabase
2. ✅ **Phase 2** : Authentification et profils de base
3. ✅ **Phase 3** : Statistiques et historique
4. ✅ **Phase 4** : Rankings personnels
5. ✅ **Phase 5** : Commentaires et social
6. ✅ **Phase 6** : Paramètres de visibilité

## 🛠️ Technologies Utilisées

### Frontend
- **Swift 5.9+**
- **SwiftUI** - Interface utilisateur moderne
- **UIKit/Texture** - Vues legacy et performance
- **Combine** - Programmation réactive
- **CoreML** - Upscaling d'images

### Backend & Cloud
- **Supabase** - Backend as a Service
  - PostgreSQL 15
  - Auth JWT
  - Realtime subscriptions
  - Row Level Security
- **CoreData** - Persistance locale
- **URLSession** - Networking

### Dépendances
- **ZIPFoundation** - Gestion des archives
- **Nuke** - Cache d'images
- **Texture (AsyncDisplayKit)** - UI performante
- **SwiftMarkdownUI** - Rendu Markdown
- **AidokuRunner** - Exécution WASM
- **Gifu** - GIF animés
- **SwiftSoup** - Parsing HTML
- **SwiftUI Introspect** - Accès aux vues UIKit

## 🔧 Développement

### Prérequis
```bash
# Xcode 15.0+
xcode-select --install

# CocoaPods (optionnel)
sudo gem install cocoapods
```

### Configuration de Développement

1. **Variables d'environnement**

   Créer `Shared/Managers/SupabaseConfig.swift` :
   ```swift
   enum SupabaseConfig {
       static let url = "https://votre-projet.supabase.co"
       static let anonKey = "votre-anon-key"
   }
   ```

2. **Base de données**
   ```bash
   # Importer le schéma
   cd bdd
   psql -h db.xxx.supabase.co -U postgres -d postgres < supabase_schema.sql

   # Voir bdd/README.md pour plus de détails
   ```

3. **Tests**
   ```bash
   # Configurer les tests
   ./scripts/setup_tests.sh

   # Exécuter les tests
   xcodebuild test -project Aidoku.xcodeproj \
     -scheme "Aidoku (iOS)" \
     -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

### Workflow de Développement

```bash
# 1. Créer une branche
git checkout -b feature/ma-nouvelle-feature

# 2. Faire vos modifications
# ...

# 3. Vérifier que tout compile
./scripts/run_tests.sh

# 4. Commit et push
git add .
git commit -m "feat: ma nouvelle feature"
git push origin feature/ma-nouvelle-feature

# 5. Créer une Pull Request
```

### Conventions de Code

- **Swift Style Guide** : [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- **Commits** : [Conventional Commits](https://www.conventionalcommits.org/)
  - `feat:` - Nouvelle fonctionnalité
  - `fix:` - Correction de bug
  - `docs:` - Documentation
  - `refactor:` - Refactoring
  - `test:` - Tests
  - `chore:` - Maintenance

## 🐛 Débogage

### Problèmes Courants

**Build échoue avec "Cannot find 'ErrorManager'"**
```bash
./scripts/add_error_manager.sh
# Suivre les instructions pour ajouter ErrorManager.swift au projet
```

**Tests ne s'exécutent pas**
```bash
./scripts/setup_tests.sh
# Configurer le target de tests dans Xcode
```

**Erreurs de synchronisation Supabase**
```bash
# Vérifier la configuration
cat Shared/Managers/SupabaseConfig.swift

# Vérifier la base de données
psql -h db.xxx.supabase.co -U postgres -d postgres < bdd/supabase_diagnostic.sql
```

Voir [`docs/debugging/`](docs/debugging/) pour plus de solutions.

## 📊 État du Projet

### ✅ Complété
- [x] Authentification Supabase
- [x] Profils utilisateur
- [x] Statistiques de lecture
- [x] Historique synchronisé
- [x] Rankings personnels
- [x] Commentaires et likes
- [x] Paramètres de visibilité
- [x] Synchronisation CoreData ↔ Supabase
- [x] Gestion d'erreurs UI (ErrorManager)
- [x] 34 tests unitaires
- [x] Documentation complète

### 🔄 En Cours
- [ ] Optimisation des performances
- [ ] Tests d'intégration
- [ ] CI/CD avec GitHub Actions

### 📋 Roadmap
- [ ] Notifications push
- [ ] Partage de listes
- [ ] Recommandations personnalisées
- [ ] Mode hors ligne amélioré
- [ ] Support iPad optimisé

## 🤝 Contribution

Les contributions sont les bienvenues ! Voici comment contribuer :

1. **Fork** le projet
2. **Créer** une branche pour votre feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** vos changements (`git commit -m 'feat: Add some AmazingFeature'`)
4. **Push** vers la branche (`git push origin feature/AmazingFeature`)
5. **Ouvrir** une Pull Request

### Guidelines
- Suivre les conventions de code Swift
- Ajouter des tests pour les nouvelles fonctionnalités
- Mettre à jour la documentation si nécessaire
- S'assurer que tous les tests passent

## 📄 License

Ce projet est basé sur [Aidoku](https://github.com/Aidoku/Aidoku) et est sous licence **GPLv3**.

Les modifications et ajouts spécifiques à TomoScan (profils, synchronisation Supabase, etc.) sont également sous **GPLv3**.

Voir [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- **[Aidoku](https://github.com/Aidoku/Aidoku)** - Projet de base
- **[Supabase](https://supabase.com)** - Backend as a Service
- **Communauté open source** - Pour tous les packages utilisés

## 📞 Contact

- **GitHub** : [@amintt2](https://github.com/amintt2)
- **Repository** : [scanio](https://github.com/amintt2/scanio)

---

**TomoScan** - Votre compagnon de lecture manga avec profils et synchronisation cloud 📱✨
