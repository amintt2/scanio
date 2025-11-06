#!/bin/bash

# ============================================
# 🧪 Script de Test Automatisé - TomoScan
# ============================================
# Ce script exécute une série de tests pour
# vérifier que l'application fonctionne correctement
# ============================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteurs
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Fonction pour afficher un test
test_start() {
    echo -e "${BLUE}🧪 Test: $1${NC}"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Fonction pour marquer un test comme réussi
test_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

# Fonction pour marquer un test comme échoué
test_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Fonction pour afficher un warning
test_warn() {
    echo -e "${YELLOW}⚠️  WARN: $1${NC}"
}

echo "============================================"
echo "🚀 Démarrage des tests TomoScan"
echo "============================================"
echo ""

# ============================================
# Test 1: Vérifier que le projet compile
# ============================================
test_start "Compilation du projet"

BUILD_OUTPUT=$(xcodebuild -project Aidoku.xcodeproj \
    -scheme "Aidoku (iOS)" \
    -configuration Debug \
    -sdk iphonesimulator \
    -skipPackagePluginValidation \
    build 2>&1 | grep -E "(\*\* BUILD)" | tail -1)

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    test_pass "Le projet compile sans erreur"
else
    test_fail "Le projet ne compile pas"
    echo "$BUILD_OUTPUT"
fi

# ============================================
# Test 2: Vérifier les fichiers critiques
# ============================================
test_start "Vérification des fichiers critiques"

CRITICAL_FILES=(
    "Shared/Managers/SupabaseManager.swift"
    "Shared/Managers/SyncManager.swift"
    "Shared/Managers/CoreData/CoreDataManager.swift"
    "Shared/Managers/CoreData/CoreDataManager+LibraryManga.swift"
    "Shared/Managers/SupabaseManager+Rankings.swift"
    "Shared/Models/UserProfile.swift"
    "iOS/New/Views/Settings/ProfileSettingsView.swift"
    "iOS/New/Views/Settings/PersonalRankingsView.swift"
    "iOS/New/Views/Settings/ReadingHistoryView.swift"
    "iOS/New/Views/Manga/MangaDetailsHeaderView.swift"
)

ALL_FILES_EXIST=true
for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (MANQUANT)"
        ALL_FILES_EXIST=false
    fi
done

if [ "$ALL_FILES_EXIST" = true ]; then
    test_pass "Tous les fichiers critiques existent"
else
    test_fail "Certains fichiers critiques sont manquants"
fi

# ============================================
# Test 3: Vérifier la configuration Supabase
# ============================================
test_start "Vérification de la configuration Supabase"

if [ -f "Shared/Managers/SupabaseConfig.swift" ]; then
    test_pass "SupabaseConfig.swift existe"
    
    # Vérifier que le fichier contient les clés nécessaires
    if grep -q "static let url" "Shared/Managers/SupabaseConfig.swift" && \
       grep -q "static let anonKey" "Shared/Managers/SupabaseConfig.swift"; then
        test_pass "SupabaseConfig contient les clés nécessaires"
    else
        test_fail "SupabaseConfig ne contient pas toutes les clés"
    fi
else
    test_fail "SupabaseConfig.swift n'existe pas"
    test_warn "Créez le fichier avec: struct SupabaseConfig { static let url = \"...\"; static let anonKey = \"...\" }"
fi

# ============================================
# Test 4: Vérifier les fonctions critiques
# ============================================
test_start "Vérification des fonctions critiques dans SupabaseManager"

FUNCTIONS_TO_CHECK=(
    "func signIn"
    "func signUp"
    "func signOut"
    "func fetchProfile"
    "func fetchUserStats"
    "func createProfile"
)

ALL_FUNCTIONS_EXIST=true
for func in "${FUNCTIONS_TO_CHECK[@]}"; do
    if grep -q "$func" "Shared/Managers/SupabaseManager.swift"; then
        echo "  ✓ $func"
    else
        echo "  ✗ $func (MANQUANT)"
        ALL_FUNCTIONS_EXIST=false
    fi
done

if [ "$ALL_FUNCTIONS_EXIST" = true ]; then
    test_pass "Toutes les fonctions critiques existent"
else
    test_fail "Certaines fonctions critiques sont manquantes"
fi

# ============================================
# Test 5: Vérifier les fonctions de rankings
# ============================================
test_start "Vérification des fonctions de rankings"

RANKING_FUNCTIONS=(
    "func upsertPersonalRanking"
    "func fetchPersonalRankings"
    "func fetchFavorites"
    "func updateRankPosition"
    "func deletePersonalRanking"
)

ALL_RANKING_FUNCTIONS_EXIST=true
for func in "${RANKING_FUNCTIONS[@]}"; do
    if grep -q "$func" "Shared/Managers/SupabaseManager+Rankings.swift"; then
        echo "  ✓ $func"
    else
        echo "  ✗ $func (MANQUANT)"
        ALL_RANKING_FUNCTIONS_EXIST=false
    fi
done

if [ "$ALL_RANKING_FUNCTIONS_EXIST" = true ]; then
    test_pass "Toutes les fonctions de rankings existent"
else
    test_fail "Certaines fonctions de rankings sont manquantes"
fi

# ============================================
# Test 6: Vérifier getLibraryMangaCount
# ============================================
test_start "Vérification de getLibraryMangaCount"

if grep -q "func getLibraryMangaCount" "Shared/Managers/CoreData/CoreDataManager+LibraryManga.swift"; then
    test_pass "getLibraryMangaCount existe"
    
    # Vérifier qu'elle accepte un paramètre context
    if grep -q "context: NSManagedObjectContext?" "Shared/Managers/CoreData/CoreDataManager+LibraryManga.swift"; then
        test_pass "getLibraryMangaCount accepte un paramètre context"
    else
        test_warn "getLibraryMangaCount ne semble pas accepter de paramètre context"
    fi
else
    test_fail "getLibraryMangaCount n'existe pas"
fi

# ============================================
# Test 7: Vérifier le bouton favori
# ============================================
test_start "Vérification du bouton favori dans MangaDetailsHeaderView"

if grep -q "func toggleFavorite" "iOS/New/Views/Manga/MangaDetailsHeaderView.swift"; then
    test_pass "toggleFavorite existe"
    
    if grep -q "func loadCanonicalMangaId" "iOS/New/Views/Manga/MangaDetailsHeaderView.swift"; then
        test_pass "loadCanonicalMangaId existe"
    else
        test_fail "loadCanonicalMangaId n'existe pas"
    fi
    
    if grep -q "heart.fill" "iOS/New/Views/Manga/MangaDetailsHeaderView.swift"; then
        test_pass "Le bouton cœur est présent"
    else
        test_fail "Le bouton cœur n'est pas présent"
    fi
else
    test_fail "toggleFavorite n'existe pas"
fi

# ============================================
# Test 8: Vérifier la sync au démarrage
# ============================================
test_start "Vérification de la sync au démarrage"

if grep -q "SyncManager.shared.syncAll" "iOS/AppDelegate.swift"; then
    test_pass "La sync est appelée dans AppDelegate"
    
    if grep -q "SupabaseManager.shared.isAuthenticated" "iOS/AppDelegate.swift"; then
        test_pass "La sync vérifie l'authentification"
    else
        test_warn "La sync ne semble pas vérifier l'authentification"
    fi
else
    test_fail "La sync n'est pas appelée dans AppDelegate"
fi

# ============================================
# Test 9: Vérifier les logs de debug
# ============================================
test_start "Vérification des logs de debug"

DEBUG_EMOJIS=("🔵" "🟢" "🔴" "❌" "✅" "📊" "❤️" "🔄")
LOGS_FOUND=0

for emoji in "${DEBUG_EMOJIS[@]}"; do
    if grep -r "$emoji" "Shared/Managers/" "iOS/New/Views/Settings/" > /dev/null 2>&1; then
        LOGS_FOUND=$((LOGS_FOUND + 1))
    fi
done

if [ $LOGS_FOUND -ge 5 ]; then
    test_pass "Les logs de debug avec emojis sont présents ($LOGS_FOUND/8 types trouvés)"
else
    test_warn "Peu de logs de debug trouvés ($LOGS_FOUND/8 types)"
fi

# ============================================
# Test 10: Vérifier les modèles de données
# ============================================
test_start "Vérification des modèles de données"

DATA_MODELS=(
    "struct UserProfile"
    "struct UserStats"
    "struct PersonalRanking"
    "struct PersonalRankingWithManga"
    "struct ReadingHistoryWithManga"
    "struct ProfileVisibilitySettings"
    "enum ReadingStatus"
)

ALL_MODELS_EXIST=true
for model in "${DATA_MODELS[@]}"; do
    if grep -q "$model" "Shared/Models/UserProfile.swift"; then
        echo "  ✓ $model"
    else
        echo "  ✗ $model (MANQUANT)"
        ALL_MODELS_EXIST=false
    fi
done

if [ "$ALL_MODELS_EXIST" = true ]; then
    test_pass "Tous les modèles de données existent"
else
    test_fail "Certains modèles de données sont manquants"
fi

# ============================================
# Résumé des tests
# ============================================
echo ""
echo "============================================"
echo "📊 Résumé des tests"
echo "============================================"
echo -e "Total:  ${BLUE}$TESTS_TOTAL${NC}"
echo -e "Réussi: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Échoué: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Tous les tests sont passés !${NC}"
    echo ""
    echo "Prochaines étapes:"
    echo "1. Exécutez supabase_diagnostic.sql dans Supabase"
    echo "2. Lancez l'app et testez manuellement"
    echo "3. Vérifiez les logs dans Xcode"
    exit 0
else
    echo -e "${RED}❌ Certains tests ont échoué${NC}"
    echo ""
    echo "Veuillez corriger les erreurs avant de continuer"
    exit 1
fi

