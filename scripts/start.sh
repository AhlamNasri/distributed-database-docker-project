#!/bin/bash
# ============================================================
# start.sh — Démarrage propre du cluster
# Usage : bash scripts/start.sh
# ============================================================

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  Démarrage du cluster EShop Distributed Database${NC}"
echo -e "${BLUE}============================================================${NC}"

# Racine du projet
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Rendre les scripts exécutables
chmod +x docker/grants.sh
chmod +x monitoring/check_health.sh
chmod +x scripts/connectivity_test.sh

echo ""
echo -e "${YELLOW}[1/4] Arrêt des conteneurs existants...${NC}"
docker-compose down -v 2>/dev/null || true

echo ""
echo -e "${YELLOW}[2/4] Démarrage des conteneurs Site1 et Site2...${NC}"
docker-compose up -d oracle-site1 oracle-site2

echo ""
echo -e "${YELLOW}[3/4] Attente que Site1 et Site2 soient healthy...${NC}"
for CONTAINER in oracle-site1 oracle-site2; do
    echo -n "  Attente $CONTAINER"
    until [ "$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER 2>/dev/null)" = "healthy" ]; do
        echo -n "."
        sleep 10
    done
    echo -e " ${GREEN}OK${NC}"
done

echo ""
echo -e "${YELLOW}[4/4] Démarrage de oracle-central (coordinateur)...${NC}"
docker-compose up -d oracle-central

echo -n "  Attente oracle-central"
until [ "$(docker inspect --format='{{.State.Health.Status}}' oracle-central 2>/dev/null)" = "healthy" ]; do
    echo -n "."
    sleep 10
done
echo -e " ${GREEN}OK${NC}"

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Cluster démarré avec succès !${NC}"
echo -e "${GREEN}  Exécutez bash scripts/connectivity_test.sh pour valider${NC}"
echo -e "${GREEN}============================================================${NC}"

echo ""
echo "Ports exposés :"
echo "  oracle-site1    → localhost:1521  (BDDVENTE   / eshop1:eshop1pass)"
echo "  oracle-site2    → localhost:1522  (BDDVENTE2  / eshop2:eshop2pass)"
echo "  oracle-central  → localhost:1523  (BDDCENTRAL / eshopcentral:centralpass)"
