# 📚 Documentation TomoScan

Bienvenue dans la documentation complète de TomoScan !

## 📁 Structure

```
docs/
├── debugging/       # Documentation de débogage et corrections
├── features/        # Plans et spécifications des fonctionnalités
├── onboarding/      # Guides d'intégration utilisateur
└── tests/           # Documentation des tests
```

## 🚀 Démarrage Rapide

**Nouveau sur le projet ?** Commencez ici :
1. **[Quick Start Guide](QUICK_START.md)** ⭐ - Installation et premiers pas
2. **[Roadmap & Améliorations](features/ROADMAP_IMPROVEMENTS.md)** ⭐ - Plan complet des features à implémenter

## 🔍 Navigation Rapide

### 🐛 Debugging
Documentation technique pour le débogage et les corrections appliquées.

**Commencez ici** : [`debugging/START_HERE.md`](debugging/START_HERE.md)

- **AMELIORATIONS_FINALES.md** - Résumé des dernières améliorations (logs, ErrorManager, tests)
- **CORRECTIONS_APPLIQUEES.md** - Détails des 5 corrections critiques
- **DEBUGGING_GUIDE.md** - Guide de débogage avec solutions aux erreurs courantes
- **DEBUGGING_SESSION_SUMMARY.md** - Résumé de la session de débogage
- **DEBUG_SESSION_REPORT.md** - Rapport complet de débogage
- **FILES_CREATED.md** - Liste des fichiers créés pendant le débogage
- **START_HERE.md** - Point de départ pour le débogage

### ✨ Features
Plans et spécifications des fonctionnalités de l'application.

- **[ROADMAP_IMPROVEMENTS.md](features/ROADMAP_IMPROVEMENTS.md)** ⭐ - Plan complet des améliorations futures (18 features)
- **PROFILE_FEATURES_PLAN.md** - Plan complet des fonctionnalités de profil (6 phases)
- **COREDATA_SUPABASE_SYNC_PLAN.md** - Architecture de synchronisation CoreData ↔ Supabase

### 👋 Onboarding
Guides pour l'intégration des nouveaux utilisateurs.

- **ONBOARDING_TUTORIAL_PLAN.md** - Plan complet du tutoriel d'onboarding
- **ONBOARDING_README.md** - Vue d'ensemble de l'onboarding
- **ONBOARDING_QUICK_START.md** - Guide de démarrage rapide

### 🧪 Tests
Documentation des tests et procédures de test.

- **TESTS_SETUP_GUIDE.md** - Guide complet pour configurer et exécuter les 34 tests XCTest

## 🗄️ Base de Données

Les fichiers SQL sont dans le dossier [`../bdd/`](../bdd/)

Voir [`../bdd/README.md`](../bdd/README.md) pour plus de détails.

## 📊 État du Projet

### ✅ Complété
- [x] Système de profil utilisateur
- [x] Synchronisation Supabase (en cours de correction)
- [x] Commentaires et likes
- [x] 34 tests unitaires
- [x] ErrorManager pour gestion d'erreurs
- [x] Organisation du projet
- [x] 5 problèmes critiques corrigés
- [x] Logs nettoyés (DEBUG seulement)

### 🚧 En Cours
- [ ] Correction de la synchronisation library/sources/history
- [ ] Correction du système de commentaires
- [ ] Changement de couleur d'accent (cyan → bleu)

### 📅 À Venir (Voir [Roadmap](features/ROADMAP_IMPROVEMENTS.md))
- [ ] Page Découvrir (nouvelle page d'accueil)
- [ ] Préchargement automatique des chapitres
- [ ] Recherche globale multi-sources
- [ ] Système de notation 0-10
- [ ] Long-term caching avec Supabase
- [ ] Swipe pour télécharger/supprimer chapitres

## 🎯 Pour les Développeurs

### Workflow Recommandé

1. **Lire le [Quick Start](QUICK_START.md)** pour comprendre la structure du projet
2. **Consulter le [Roadmap](features/ROADMAP_IMPROVEMENTS.md)** pour voir les features à implémenter
3. **Suivre les conventions** de code et de commits
4. **Tester** avant de commit

### Build Commands

```bash
# Build iOS
xcodebuild -project Aidoku.xcodeproj -scheme "Aidoku (iOS)" build

# Run tests
xcodebuild test -project Aidoku.xcodeproj -scheme "Aidoku (iOS)"

# Clean
xcodebuild clean -project Aidoku.xcodeproj -scheme "Aidoku (iOS)"
```

### Conventions de Commits

```bash
git commit -m "fix(sync): correct library upload to Supabase"
git commit -m "feat(discover): add discover page"
git commit -m "refactor(profile): move profile out of settings"
git commit -m "test(sync): add tests for library sync"
```

## 🛠️ Outils et Scripts

Les scripts utiles sont à la racine du projet :
- `setup_tests.sh` - Configuration des tests
- `add_error_manager.sh` - Instructions pour ajouter ErrorManager
- `run_tests.sh` - Exécution des tests automatisés

## 📝 Conventions

### Fichiers Markdown
- **MAJUSCULES_AVEC_UNDERSCORES.md** - Documentation principale
- **README.md** - Index et navigation

### Organisation
- Un dossier par thème
- README.md dans chaque dossier
- Fichiers triés par sujet

## 🔗 Liens Utiles

- [README principal](../README.md)
- [Base de données](../bdd/README.md)
- [Tests](tests/TESTS_SETUP_GUIDE.md)
- [Débogage](debugging/START_HERE.md)

---

**Dernière mise à jour** : 2025-11-06  
**Version** : 1.0

