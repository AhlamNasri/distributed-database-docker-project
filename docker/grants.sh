#!/bin/bash
# ============================================================
# grants.sh — Accordé par le DBA (SYSTEM) à l'APP_USER
# Octroie les privilèges supplémentaires nécessaires :
#   - CREATE DATABASE LINK  (pour les liens inter-sites)
#   - CREATE SYNONYM         (pour l'accès transparent)
#   - CREATE VIEW            (pour les vues distribuées)
# Ce script est sourcé par l'image gvenzl/oracle-xe
# lors de l'initialisation (docker-entrypoint-initdb.d)
# ============================================================

echo "[grants.sh] Octroi des privilèges à ${APP_USER} sur ${ORACLE_DATABASE}..."

sqlplus -s "sys/${ORACLE_PASSWORD}@//localhost:1521/${ORACLE_DATABASE} as sysdba" <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE;

GRANT CREATE DATABASE LINK TO ${APP_USER};
GRANT CREATE SYNONYM       TO ${APP_USER};
GRANT CREATE VIEW          TO ${APP_USER};
GRANT CREATE SESSION       TO ${APP_USER};

-- Confirme les grants
SELECT PRIVILEGE, GRANTEE
FROM DBA_SYS_PRIVS
WHERE GRANTEE = UPPER('${APP_USER}')
  AND PRIVILEGE IN ('CREATE DATABASE LINK','CREATE SYNONYM','CREATE VIEW')
ORDER BY PRIVILEGE;

COMMIT;
EXIT;
EOF

echo "[grants.sh] Privilèges accordés à ${APP_USER}."
