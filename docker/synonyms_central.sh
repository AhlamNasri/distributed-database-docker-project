#!/bin/bash
# ============================================================
# synonyms_central.sh — Synonymes sur oracle-central
# Connecté comme APP_USER (eshopcentral) dans BDDCENTRAL
# ============================================================
echo "[synonyms_central.sh] Creating synonyms as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE OR REPLACE SYNONYM LigneCommandes1 FOR LigneCommandes1@site1_link;
CREATE OR REPLACE SYNONYM Commandes1      FOR Commandes1@site1_link;
CREATE OR REPLACE SYNONYM Clients1        FOR Clients1@site1_link;
CREATE OR REPLACE SYNONYM Produits1       FOR Produits1@site1_link;

CREATE OR REPLACE SYNONYM LigneCommandes2 FOR LigneCommandes2@site2_link;
CREATE OR REPLACE SYNONYM Commandes2      FOR Commandes2@site2_link;
CREATE OR REPLACE SYNONYM Clients2        FOR Clients2@site2_link;
CREATE OR REPLACE SYNONYM Produits2       FOR Produits2@site2_link;

CREATE OR REPLACE SYNONYM LigneCommandes1_sc1 FOR LigneCommandes1_sc1@site1_link;
CREATE OR REPLACE SYNONYM Produits1_sc1       FOR Produits1_sc1@site1_link;
CREATE OR REPLACE SYNONYM Categories1_sc1     FOR Categories1_sc1@site1_link;
CREATE OR REPLACE SYNONYM LigneCommandes2_sc1 FOR LigneCommandes2_sc1@site2_link;
CREATE OR REPLACE SYNONYM Produits2_sc1       FOR Produits2_sc1@site2_link;
CREATE OR REPLACE SYNONYM Categories2_sc1     FOR Categories2_sc1@site2_link;

CREATE OR REPLACE FORCE VIEW V_LIGNECOMMANDES_GLOBAL_SYN AS
    SELECT 'SITE1' AS SITE, lc.* FROM LigneCommandes1 lc
    UNION ALL
    SELECT 'SITE2' AS SITE, lc.* FROM LigneCommandes2 lc;

COMMIT;
EXIT;
SQLEOF

echo "[synonyms_central.sh] Done."
