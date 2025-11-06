#!/bin/bash

# Script pour configurer les tests TomoScan
# Ce script guide l'utilisateur pour ajouter le target de tests dans Xcode

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║          🧪 Configuration des Tests TomoScan 🧪              ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier que les fichiers de tests existent
echo -e "${BLUE}📁 Vérification des fichiers de tests...${NC}"
echo ""

FILES=(
    "TomoScanTests/SupabaseManagerTests.swift"
    "TomoScanTests/UserProfileTests.swift"
    "TomoScanTests/NetworkTests.swift"
    "TomoScanTests/Info.plist"
)

ALL_FILES_EXIST=true
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file (MANQUANT)"
        ALL_FILES_EXIST=false
    fi
done

echo ""

if [ "$ALL_FILES_EXIST" = false ]; then
    echo -e "${RED}❌ Certains fichiers de tests sont manquants${NC}"
    echo -e "${YELLOW}Veuillez créer les fichiers manquants avant de continuer${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Tous les fichiers de tests sont présents${NC}"
echo ""

# Vérifier que le projet existe
if [ ! -f "Aidoku.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Projet Xcode non trouvé${NC}"
    echo -e "${YELLOW}Assurez-vous d'être dans le répertoire racine du projet${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Projet Xcode trouvé${NC}"
echo ""

# Instructions pour l'utilisateur
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║                  📋 INSTRUCTIONS MANUELLES                   ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${YELLOW}⚠️  L'ajout du target de tests doit être fait manuellement dans Xcode${NC}"
echo ""
echo "Suivez ces étapes :"
echo ""
echo -e "${BLUE}1.${NC} Ouvrir Xcode"
echo "   ${GREEN}open Aidoku.xcodeproj${NC}"
echo ""
echo -e "${BLUE}2.${NC} Créer un nouveau Test Target"
echo "   • Cliquer sur le projet 'Aidoku' dans le navigateur"
echo "   • Cliquer sur le '+' en bas de la liste des targets"
echo "   • Choisir 'iOS' → 'Unit Testing Bundle'"
echo "   • Nom: ${GREEN}TomoScanTests${NC}"
echo "   • Target to be Tested: ${GREEN}Aidoku (iOS)${NC}"
echo "   • Cliquer 'Finish'"
echo ""
echo -e "${BLUE}3.${NC} Supprimer le fichier de test par défaut"
echo "   • Xcode crée un fichier 'TomoScanTestsTests.swift'"
echo "   • Le supprimer (Move to Trash)"
echo ""
echo -e "${BLUE}4.${NC} Ajouter les fichiers de tests existants"
echo "   • Clic droit sur le groupe 'TomoScanTests' dans Xcode"
echo "   • 'Add Files to TomoScanTests...'"
echo "   • Sélectionner tous les fichiers .swift dans TomoScanTests/"
echo "   • ✅ Cocher 'Copy items if needed'"
echo "   • ✅ Cocher 'TomoScanTests' dans 'Add to targets'"
echo "   • Cliquer 'Add'"
echo ""
echo -e "${BLUE}5.${NC} Configurer le Bundle Identifier"
echo "   • Sélectionner le target 'TomoScanTests'"
echo "   • Onglet 'Build Settings'"
echo "   • Chercher 'Bundle Identifier'"
echo "   • Définir: ${GREEN}xyz.skitty.Aidoku.TomoScanTests${NC}"
echo ""
echo -e "${BLUE}6.${NC} Activer Testing Search Paths"
echo "   • Dans 'Build Settings'"
echo "   • Chercher 'Enable Testing Search Paths'"
echo "   • Définir à ${GREEN}Yes${NC}"
echo ""
echo -e "${BLUE}7.${NC} Exécuter les tests"
echo "   • Appuyer sur ${GREEN}Cmd + U${NC}"
echo "   • Ou cliquer sur le bouton ▶ dans le Test Navigator (Cmd + 6)"
echo ""

# Demander si l'utilisateur veut ouvrir Xcode
echo ""
read -p "Voulez-vous ouvrir Xcode maintenant ? (o/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[OoYy]$ ]]; then
    echo -e "${GREEN}🚀 Ouverture de Xcode...${NC}"
    open Aidoku.xcodeproj
    echo ""
    echo -e "${BLUE}📖 Consultez TESTS_SETUP_GUIDE.md pour plus de détails${NC}"
else
    echo -e "${YELLOW}Vous pouvez ouvrir Xcode plus tard avec:${NC}"
    echo -e "${GREEN}open Aidoku.xcodeproj${NC}"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║              ✅ Configuration prête à démarrer !             ║"
echo "║                                                              ║"
echo "║  📖 Lisez TESTS_SETUP_GUIDE.md pour les instructions        ║"
echo "║     détaillées et la liste complète des tests               ║"
echo "║                                                              ║"
echo "║  🧪 Total: 32 tests créés                                   ║"
echo "║     • SupabaseManagerTests: 9 tests                         ║"
echo "║     • UserProfileTests: 10 tests                            ║"
echo "║     • NetworkTests: 13 tests                                ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

