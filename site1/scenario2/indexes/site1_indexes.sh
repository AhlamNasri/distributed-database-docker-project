#!/bin/bash
# ============================================================
# site1_indexes.sh — Index Site1 Scénario 2
# Connecté comme APP_USER (eshop1) dans BDDVENTE
# ============================================================
echo "[site1_indexes.sh] Creating indexes as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE INDEX idx_lc1_quantite   ON LigneCommandes1 (QUANTITE);
CREATE INDEX idx_lc1_idcommande ON LigneCommandes1 (IDCOMMANDE);
CREATE INDEX idx_lc1_idproduit  ON LigneCommandes1 (IDPRODUIT);
CREATE INDEX idx_lc1_cmd_qte    ON LigneCommandes1 (IDCOMMANDE, QUANTITE);
CREATE INDEX idx_cmd1_idclient  ON Commandes1 (IDCLIENT);
CREATE INDEX idx_cmd1_date      ON Commandes1 (DATECOMMANDE);
CREATE INDEX idx_prod1_idcateg  ON Produits1 (IDCATEG);
CREATE INDEX idx_prod1_prix     ON Produits1 (PRIXUNITAIRE);
CREATE INDEX idx_cli1_pays      ON Clients1 (PAYS);
CREATE INDEX idx_cli1_ville     ON Clients1 (VILLE);

COMMIT;
EXIT;
SQLEOF

echo "[site1_indexes.sh] Done."
