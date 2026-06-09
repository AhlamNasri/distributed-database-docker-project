#!/bin/bash
# ============================================================
# site1_synonyms.sh — Synonymes + Vues distribuées Site1
# Connecté comme APP_USER (eshop1) dans BDDVENTE
# Inclut V_TOUTES_LIGNES (déplacée depuis site1_dblinks.sh)
# ============================================================
echo "[site1_synonyms.sh] Creating synonyms and views as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE OR REPLACE SYNONYM S2_LigneCommandes FOR LigneCommandes2@site2_link;
CREATE OR REPLACE SYNONYM S2_Commandes      FOR Commandes2@site2_link;
CREATE OR REPLACE SYNONYM S2_Clients        FOR Clients2@site2_link;
CREATE OR REPLACE SYNONYM S2_Produits       FOR Produits2@site2_link;

CREATE OR REPLACE FORCE VIEW V_LIGNES_GLOBAL AS
    SELECT 'SITE1' AS SITE, lc.*
    FROM LigneCommandes1 lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.*
    FROM S2_LigneCommandes lc;

CREATE OR REPLACE FORCE VIEW V_TOUTES_LIGNES AS
    SELECT 'SITE1' AS SITE, lc.*
    FROM LigneCommandes1 lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.*
    FROM LigneCommandes2@site2_link lc;

COMMIT;
EXIT;
SQLEOF

echo "[site1_synonyms.sh] Done."
