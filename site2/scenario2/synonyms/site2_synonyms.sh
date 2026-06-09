#!/bin/bash
# ============================================================
# site2_synonyms.sh — Synonymes + Vues distribuées Site2
# Connecté comme APP_USER (eshop2) dans BDDVENTE2
# Inclut V_TOUTES_LIGNES (déplacée depuis site2_dblinks.sh)
# ============================================================
echo "[site2_synonyms.sh] Creating synonyms and views as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE OR REPLACE SYNONYM S1_LigneCommandes FOR LigneCommandes1@site1_link;
CREATE OR REPLACE SYNONYM S1_Commandes      FOR Commandes1@site1_link;
CREATE OR REPLACE SYNONYM S1_Clients        FOR Clients1@site1_link;
CREATE OR REPLACE SYNONYM S1_Produits       FOR Produits1@site1_link;

CREATE OR REPLACE FORCE VIEW V_LIGNES_GLOBAL AS
    SELECT 'SITE1' AS SITE, lc.*
    FROM S1_LigneCommandes lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.*
    FROM LigneCommandes2 lc;

CREATE OR REPLACE FORCE VIEW V_TOUTES_LIGNES AS
    SELECT 'SITE1' AS SITE, lc.*
    FROM LigneCommandes1@site1_link lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.*
    FROM LigneCommandes2 lc;

COMMIT;
EXIT;
SQLEOF

echo "[site2_synonyms.sh] Done."
