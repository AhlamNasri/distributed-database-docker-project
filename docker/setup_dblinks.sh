#!/bin/bash
# ============================================================
# setup_dblinks.sh — DB Links + Vues distribuées sur oracle-central
# Connecté comme APP_USER (eshopcentral) dans BDDCENTRAL
# ============================================================
echo "[setup_dblinks.sh] Creating DB links and views as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE DATABASE LINK site1_link
  CONNECT TO eshop1 IDENTIFIED BY eshop1pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site1)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE))
  )';

CREATE DATABASE LINK site2_link
  CONNECT TO eshop2 IDENTIFIED BY eshop2pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site2)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE2))
  )';

CREATE OR REPLACE FORCE VIEW V_LIGNECOMMANDES_GLOBAL AS
  SELECT 'SITE1' AS SITE, lc.* FROM LigneCommandes1@site1_link lc
  UNION ALL
  SELECT 'SITE2' AS SITE, lc.* FROM LigneCommandes2@site2_link lc;

CREATE OR REPLACE FORCE VIEW V_LIGNECOMMANDES_GLOBAL_SC1 AS
  SELECT 'SITE1' AS SITE, lc.* FROM LigneCommandes1_sc1@site1_link lc
  UNION ALL
  SELECT 'SITE2' AS SITE, lc.* FROM LigneCommandes2_sc1@site2_link lc;

CREATE OR REPLACE FORCE VIEW V_PRODUITS_GLOBAL AS
  SELECT 'SITE1' AS SITE, p.* FROM Produits1@site1_link p
  UNION ALL
  SELECT 'SITE2' AS SITE, p.* FROM Produits2@site2_link p;

CREATE OR REPLACE FORCE VIEW V_COMMANDES_GLOBAL AS
  SELECT 'SITE1' AS SITE, c.* FROM Commandes1@site1_link c
  UNION ALL
  SELECT 'SITE2' AS SITE, c.* FROM Commandes2@site2_link c;

COMMIT;
EXIT;
SQLEOF

echo "[setup_dblinks.sh] Done."
