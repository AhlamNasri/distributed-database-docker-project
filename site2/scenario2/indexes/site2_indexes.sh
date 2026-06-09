#!/bin/bash
# ============================================================
# site2_indexes.sh — Index Site2 Scénario 2
# Connecté comme APP_USER (eshop2) dans BDDVENTE2
# ============================================================
echo "[site2_indexes.sh] Creating indexes as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE INDEX idx_lc2_quantite   ON LigneCommandes2 (QUANTITE);
CREATE INDEX idx_lc2_idcommande ON LigneCommandes2 (IDCOMMANDE);
CREATE INDEX idx_lc2_idproduit  ON LigneCommandes2 (IDPRODUIT);
CREATE INDEX idx_lc2_prod_cmd   ON LigneCommandes2 (IDPRODUIT, IDCOMMANDE);
CREATE INDEX idx_cmd2_idclient  ON Commandes2 (IDCLIENT);
CREATE INDEX idx_cmd2_date      ON Commandes2 (DATECOMMANDE);
CREATE INDEX idx_prod2_idcateg  ON Produits2 (IDCATEG);
CREATE INDEX idx_prod2_prix     ON Produits2 (PRIXUNITAIRE);
CREATE INDEX idx_prod2_idfour   ON Produits2 (IDFOUR);
CREATE INDEX idx_cli2_pays      ON Clients2 (PAYS);
CREATE INDEX idx_cli2_ville     ON Clients2 (VILLE);

COMMIT;
EXIT;
SQLEOF

echo "[site2_indexes.sh] Done."
