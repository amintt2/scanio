#!/bin/bash

# Script pour ajouter ErrorManager.swift au projet Xcode

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║          📁 Ajout de ErrorManager.swift au projet            ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier que le fichier existe
if [ ! -f "Shared/Managers/ErrorManager.swift" ]; then
    echo -e "${YELLOW}❌ ErrorManager.swift n'existe pas${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ErrorManager.swift trouvé${NC}"
echo ""

# Instructions
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║                  📋 INSTRUCTIONS MANUELLES                   ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${YELLOW}⚠️  Le fichier doit être ajouté manuellement dans Xcode${NC}"
echo ""
echo "Suivez ces étapes :"
echo ""
echo -e "${BLUE}1.${NC} Ouvrir Xcode"
echo "   ${GREEN}open Aidoku.xcodeproj${NC}"
echo ""
echo -e "${BLUE}2.${NC} Ajouter ErrorManager.swift"
echo "   • Clic droit sur le dossier ${GREEN}Shared/Managers${NC} dans Xcode"
echo "   • Choisir 'Add Files to \"Aidoku\"...'"
echo "   • Naviguer vers ${GREEN}Shared/Managers/ErrorManager.swift${NC}"
echo "   • ✅ Cocher 'Copy items if needed'"
echo "   • ✅ Cocher les deux targets:"
echo "     - Aidoku (iOS)"
echo "     - Aidoku (macOS)"
echo "   • Cliquer 'Add'"
echo ""
echo -e "${BLUE}3.${NC} Vérifier que le fichier est ajouté"
echo "   • Le fichier devrait apparaître dans Shared/Managers"
echo "   • Sélectionner le fichier"
echo "   • Dans le panneau de droite, vérifier que les deux targets sont cochés"
echo ""
echo -e "${BLUE}4.${NC} Compiler le projet"
echo "   • Appuyer sur ${GREEN}Cmd + B${NC}"
echo "   • Vérifier qu'il n'y a pas d'erreurs"
echo ""

# Demander si l'utilisateur veut ouvrir Xcode
echo ""
read -p "Voulez-vous ouvrir Xcode maintenant ? (o/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[OoYy]$ ]]; then
    echo -e "${GREEN}🚀 Ouverture de Xcode...${NC}"
    open Aidoku.xcodeproj
    echo ""
    echo -e "${BLUE}📖 Suivez les instructions ci-dessus pour ajouter le fichier${NC}"
else
    echo -e "${YELLOW}Vous pouvez ouvrir Xcode plus tard avec:${NC}"
    echo -e "${GREEN}open Aidoku.xcodeproj${NC}"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║              ✅ Instructions affichées !                     ║"
echo "║                                                              ║"
echo "║  Après avoir ajouté le fichier dans Xcode:                  ║"
echo "║  • Compiler avec Cmd + B                                    ║"
echo "║  • Vérifier qu'il n'y a pas d'erreurs                       ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

