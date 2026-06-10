#!/bin/bash
# ============================================================
# site2_fragments.sh — Fragmentation horizontale Site2
# Règle : QUANTITE < 100
# Connecté comme APP_USER (eshop2) dans BDDVENTE2
# ============================================================
echo "[site2_fragments.sh] Creating fragments as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE TABLE Clients2 AS
SELECT DISTINCT cl.*
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE < 100;

ALTER TABLE Clients2 ADD PRIMARY KEY (IDCLIENT);

CREATE TABLE Commandes2 AS
SELECT DISTINCT c.*
FROM COMMANDES c
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE < 100;

ALTER TABLE Commandes2 ADD PRIMARY KEY (IDCOMMANDE);
ALTER TABLE Commandes2 ADD CONSTRAINT fk_cmd2_client
    FOREIGN KEY (IDCLIENT) REFERENCES Clients2(IDCLIENT);

CREATE TABLE Produits2 AS
SELECT DISTINCT p.*
FROM PRODUITS p
JOIN LIGNECOMMANDES lc ON p.IDPRODUIT = lc.IDPRODUIT
WHERE lc.QUANTITE < 100;

ALTER TABLE Produits2 ADD PRIMARY KEY (IDPRODUIT);

CREATE TABLE LigneCommandes2 AS
SELECT lc.*
FROM LIGNECOMMANDES lc
WHERE lc.QUANTITE < 100;

ALTER TABLE LigneCommandes2 ADD PRIMARY KEY (IDLIGNECOMMANDE);
ALTER TABLE LigneCommandes2 ADD CONSTRAINT fk_lc2_cmd
    FOREIGN KEY (IDCOMMANDE) REFERENCES Commandes2(IDCOMMANDE);
ALTER TABLE LigneCommandes2 ADD CONSTRAINT fk_lc2_prod
    FOREIGN KEY (IDPRODUIT) REFERENCES Produits2(IDPRODUIT);
ALTER TABLE LigneCommandes2 ADD CONSTRAINT chk_sc2_site2_qte
    CHECK (QUANTITE < 100);

-- Suppression des 25 lignes redondantes : le fragment LigneCommandes2 prend le relais
TRUNCATE TABLE LIGNECOMMANDES;

COMMIT;
EXIT;
SQLEOF

echo "[site2_fragments.sh] Done."
