#!/bin/bash
# ============================================================
# site2_dblinks.sh — Database Links sortants de oracle-site2
# Connecté comme APP_USER (eshop2) dans BDDVENTE2
# NOTE: V_TOUTES_LIGNES est créée dans site2_synonyms.sh (étape 09)
# ============================================================
echo "[site2_dblinks.sh] Creating DB links as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE DATABASE LINK site1_link
  CONNECT TO eshop1 IDENTIFIED BY eshop1pass
  USING '(DESCRIPTION=
    (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site1)(PORT=1521))
    (CONNECT_DATA=(SERVICE_NAME=BDDVENTE))
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

echo "[site2_dblinks.sh] Done."
