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

## 🚀 Démarrage Rapide

### Pour déboguer l'application
```bash
cd docs/debugging
open START_HERE.md
```

### Pour comprendre les fonctionnalités
```bash
cd docs/features
open PROFILE_FEATURES_PLAN.md
```

### Pour configurer les tests
```bash
cd docs/tests
open TESTS_SETUP_GUIDE.md
```

## 📊 État du Projet

### ✅ Complété
- 5 problèmes critiques corrigés
- 34 tests XCTest créés
- ErrorManager pour gestion d'erreurs UI
- Logs nettoyés (DEBUG seulement)
- Documentation complète

### 🔄 En cours
- Configuration du target de tests dans Xcode
- Intégration de ErrorBanner dans les vues
- Tests en conditions réelles

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

