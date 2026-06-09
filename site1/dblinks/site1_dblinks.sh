#!/bin/bash
# ============================================================
# site1_dblinks.sh — Database Links sortants de oracle-site1
# Connecté comme APP_USER (eshop1) dans BDDVENTE
# NOTE: V_TOUTES_LIGNES est créée dans site1_synonyms.sh (étape 09)
#       car elle dépend des tables fragment (créées à l'étape 05)
# ============================================================
echo "[site1_dblinks.sh] Creating DB links as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE DATABASE LINK site2_link
  CONNECT TO eshop2 IDENTIFIED BY eshop2pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site2)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE2))
  )';

CREATE DATABASE LINK central_link
  CONNECT TO eshopcentral IDENTIFIED BY centralpass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-central)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDCENTRAL))
  )';

COMMIT;
EXIT;
SQLEOF

echo "[site1_dblinks.sh] Done."
