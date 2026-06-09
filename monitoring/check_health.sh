#!/bin/bash
# ============================================================
# check_health.sh
# Surveillance complète du cluster de bases de données
# Usage : bash monitoring/check_health.sh
# Prérequis : Docker en cours d'exécution, containers démarrés
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  HEALTH CHECK — Distributed EShop Database Cluster${NC}"
echo -e "${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}============================================================${NC}"

# -------------------------------------------------------
# 1. Vérification des conteneurs Docker
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}--- 1. État des conteneurs Docker ---${NC}"
CONTAINERS=("oracle-site1" "oracle-site2" "oracle-central")

for CONTAINER in "${CONTAINERS[@]}"; do
    STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER" 2>/dev/null)
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null)

    if [ -z "$STATUS" ]; then
        echo -e "  ${RED}✗ $CONTAINER : conteneur introuvable${NC}"
    elif [ "$HEALTH" = "healthy" ]; then
        echo -e "  ${GREEN}✓ $CONTAINER : $STATUS ($HEALTH)${NC}"
    elif [ "$HEALTH" = "starting" ]; then
        echo -e "  ${YELLOW}⏳ $CONTAINER : $STATUS ($HEALTH — démarrage en cours)${NC}"
    else
        echo -e "  ${RED}✗ $CONTAINER : $STATUS ($HEALTH)${NC}"
    fi
done

# -------------------------------------------------------
# 2. Utilisation mémoire et CPU
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}--- 2. Ressources des conteneurs ---${NC}"
docker stats --no-stream --format \
    "  {{.Name}}: CPU={{.CPUPerc}} | MEM={{.MemUsage}} | NET={{.NetIO}}" \
    oracle-site1 oracle-site2 oracle-central 2>/dev/null || \
    echo -e "  ${RED}Impossible de récupérer les statistiques${NC}"

# -------------------------------------------------------
# 3. Test de connectivité réseau (ping inter-conteneurs)
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}--- 3. Connectivité réseau (ping) ---${NC}"

ping_test() {
    local FROM=$1
    local TO=$2
    RESULT=$(docker exec "$FROM" ping -c 1 -W 2 "$TO" 2>/dev/null | tail -1)
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ $FROM → $TO : OK${NC}  ($RESULT)"
    else
        echo -e "  ${RED}✗ $FROM → $TO : ECHEC${NC}"
    fi
}

ping_test "oracle-site1"    "oracle-site2"
ping_test "oracle-site1"    "oracle-central"
ping_test "oracle-site2"    "oracle-site1"
ping_test "oracle-site2"    "oracle-central"
ping_test "oracle-central"  "oracle-site1"
ping_test "oracle-central"  "oracle-site2"

# -------------------------------------------------------
# 4. Test de connexion SQL*Plus
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}--- 4. Connexions SQL*Plus ---${NC}"

sqlplus_test() {
    local CONTAINER=$1
    local USER=$2
    local PASS=$3
    local DB=$4
    local LABEL=$5

    RESULT=$(docker exec "$CONTAINER" \
        sqlplus -s "${USER}/${PASS}@//localhost:1521/${DB}" \
        <<< "SELECT 'CONNECTED' FROM DUAL;" 2>/dev/null | grep "CONNECTED")

    if [ "$RESULT" = "CONNECTED" ]; then
        echo -e "  ${GREEN}✓ $LABEL : connexion OK${NC}"
    else
        echo -e "  ${RED}✗ $LABEL : ECHEC de connexion${NC}"
    fi
}

sqlplus_test "oracle-site1"   "eshop1"       "eshop1pass"  "BDDVENTE"   "Site1 (eshop1@BDDVENTE)"
sqlplus_test "oracle-site2"   "eshop2"       "eshop2pass"  "BDDVENTE2"  "Site2 (eshop2@BDDVENTE2)"
sqlplus_test "oracle-central" "eshopcentral" "centralpass" "BDDCENTRAL" "Central (eshopcentral@BDDCENTRAL)"

# -------------------------------------------------------
# 5. Test des Database Links depuis oracle-central
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}--- 5. Database Links (depuis oracle-central) ---${NC}"

dblink_test() {
    local LINK=$1
    local TABLE=$2
    RESULT=$(docker exec oracle-central \
        sqlplus -s "eshopcentral/centralpass@//localhost:1521/BDDCENTRAL" \
        <<< "SELECT COUNT(*) AS CNT FROM ${TABLE}@${LINK};" 2>/dev/null | grep -E '^[0-9]+')

    if [ -n "$RESULT" ]; then
        echo -e "  ${GREEN}✓ $LINK ($TABLE) : $RESULT ligne(s)${NC}"
    else
        echo -e "  ${RED}✗ $LINK ($TABLE) : ECHEC${NC}"
    fi
}

dblink_test "site1_link" "LigneCommandes1"
dblink_test "site2_link" "LigneCommandes2"

# -------------------------------------------------------
# 6. Comptage des tables de fragments
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}--- 6. Données dans les fragments ---${NC}"

count_table() {
    local CONTAINER=$1
    local USER=$2
    local PASS=$3
    local DB=$4
    local TABLE=$5

    COUNT=$(docker exec "$CONTAINER" \
        sqlplus -s "${USER}/${PASS}@//localhost:1521/${DB}" \
        <<< "SELECT COUNT(*) FROM ${TABLE};" 2>/dev/null | grep -E '^[0-9]+')
    echo -e "  $CONTAINER.$TABLE : ${COUNT:-ERREUR} ligne(s)"
}

count_table "oracle-site1" "eshop1" "eshop1pass" "BDDVENTE"  "LigneCommandes1"
count_table "oracle-site2" "eshop2" "eshop2pass" "BDDVENTE2" "LigneCommandes2"

# -------------------------------------------------------
# 7. Résumé final
# -------------------------------------------------------
echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  Health Check terminé — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}============================================================${NC}"
