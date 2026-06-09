#!/bin/bash
# ============================================================
# connectivity_test.sh
# Tests de connectivité réseau et SQL complets
# Usage : bash scripts/connectivity_test.sh
# Prérequis : les 3 conteneurs doivent être up et healthy
# ============================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

check() {
    if [ $1 -eq 0 ]; then
        echo -e "  ${GREEN}[PASS]${NC} $2"
        ((PASS_COUNT++))
    else
        echo -e "  ${RED}[FAIL]${NC} $2"
        ((FAIL_COUNT++))
    fi
}

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}  CONNECTIVITY TEST — Distributed EShop${NC}"
echo -e "${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}============================================================${NC}"

# -------------------------------------------------------
# SECTION 1 : TCP inter-conteneurs (port 1521)
# Remplace ping — absent de l'image gvenzl/oracle-xe:21-slim
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== SECTION 1 : Connectivité TCP inter-conteneurs (port 1521) ===${NC}"

do_tcp_inter() {
    local FROM=$1 TO=$2
    docker exec "$FROM" bash -c \
        "timeout 3 bash -c 'cat < /dev/null > /dev/tcp/$TO/1521'" > /dev/null 2>&1
    check $? "TCP $FROM → $TO:1521"
}

do_tcp_inter "oracle-site1"   "oracle-site2"
do_tcp_inter "oracle-site1"   "oracle-central"
do_tcp_inter "oracle-site2"   "oracle-site1"
do_tcp_inter "oracle-site2"   "oracle-central"
do_tcp_inter "oracle-central" "oracle-site1"
do_tcp_inter "oracle-central" "oracle-site2"

# -------------------------------------------------------
# SECTION 2 : Connexions SQL*Plus locales
# Utilise printf + pipe + -i pour passer stdin à docker exec
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== SECTION 2 : Connexions SQL*Plus locales ===${NC}"

do_sqlplus() {
    local CONTAINER=$1 USER=$2 PASS=$3 DB=$4 LABEL=$5
    RESULT=$(printf "SET HEADING OFF\nSELECT 'OK' FROM DUAL;\nEXIT;\n" \
        | docker exec -i "$CONTAINER" \
            sqlplus -s "${USER}/${PASS}@//localhost:1521/${DB}" 2>/dev/null \
        | tr -d ' \n\r')
    [ "$RESULT" = "OK" ]
    check $? "SQL*Plus $LABEL"
}

do_sqlplus "oracle-site1"   "eshop1"       "eshop1pass"  "BDDVENTE"   "eshop1@BDDVENTE"
do_sqlplus "oracle-site2"   "eshop2"       "eshop2pass"  "BDDVENTE2"  "eshop2@BDDVENTE2"
do_sqlplus "oracle-central" "eshopcentral" "centralpass" "BDDCENTRAL" "eshopcentral@BDDCENTRAL"

# -------------------------------------------------------
# SECTION 3 : Database Links depuis oracle-central
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== SECTION 3 : Database Links depuis oracle-central ===${NC}"

do_dblink() {
    local LINK=$1
    RESULT=$(printf "SET HEADING OFF\nSELECT 'LINK_OK' FROM DUAL@${LINK};\nEXIT;\n" \
        | docker exec -i oracle-central \
            sqlplus -s "eshopcentral/centralpass@//localhost:1521/BDDCENTRAL" 2>/dev/null \
        | tr -d ' \n\r')
    [ "$RESULT" = "LINK_OK" ]
    check $? "DB Link central → $LINK"
}

do_dblink "site1_link"
do_dblink "site2_link"

# -------------------------------------------------------
# SECTION 4 : Database Links bidirectionnels (site1 ↔ site2)
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== SECTION 4 : Database Links bidirectionnels ===${NC}"

do_dblink_from() {
    local CONTAINER=$1 USER=$2 PASS=$3 DB=$4 LINK=$5
    RESULT=$(printf "SET HEADING OFF\nSELECT 'LINK_OK' FROM DUAL@${LINK};\nEXIT;\n" \
        | docker exec -i "$CONTAINER" \
            sqlplus -s "${USER}/${PASS}@//localhost:1521/${DB}" 2>/dev/null \
        | tr -d ' \n\r')
    [ "$RESULT" = "LINK_OK" ]
    check $? "DB Link $CONTAINER → $LINK"
}

do_dblink_from "oracle-site1" "eshop1" "eshop1pass" "BDDVENTE"  "site2_link"
do_dblink_from "oracle-site1" "eshop1" "eshop1pass" "BDDVENTE"  "central_link"
do_dblink_from "oracle-site2" "eshop2" "eshop2pass" "BDDVENTE2" "site1_link"
do_dblink_from "oracle-site2" "eshop2" "eshop2pass" "BDDVENTE2" "central_link"

# -------------------------------------------------------
# SECTION 5 : Requêtes distribuées de validation
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}=== SECTION 5 : Requêtes distribuées ===${NC}"

echo "  [INFO] Comptage global (Scénario 2) depuis oracle-central :"
printf "SET HEADING ON\nSET LINESIZE 80\nSELECT 'SITE1' AS SITE, COUNT(*) AS NB_LIGNES, SUM(QUANTITE) AS QTE_TOTALE FROM LigneCommandes1@site1_link UNION ALL SELECT 'SITE2', COUNT(*), SUM(QUANTITE) FROM LigneCommandes2@site2_link;\nEXIT;\n" \
    | docker exec -i oracle-central \
        sqlplus -s "eshopcentral/centralpass@//localhost:1521/BDDCENTRAL" 2>/dev/null

# -------------------------------------------------------
# BILAN
# -------------------------------------------------------
echo ""
echo -e "${BLUE}============================================================${NC}"
TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo -e "  Résultat : ${GREEN}$PASS_COUNT PASS${NC} / ${RED}$FAIL_COUNT FAIL${NC} / $TOTAL tests"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "  ${GREEN}✓ Tous les tests sont PASSÉS — cluster opérationnel${NC}"
else
    echo -e "  ${RED}✗ $FAIL_COUNT test(s) ont ÉCHOUÉ — vérifier les logs${NC}"
fi
echo -e "${BLUE}============================================================${NC}"
