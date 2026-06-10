#!/bin/bash
# ============================================================
# site1_fragments.sh — Fragmentation horizontale Site1
# Règle : QUANTITE >= 100
# Connecté comme APP_USER (eshop1) dans BDDVENTE
# ============================================================
echo "[site1_fragments.sh] Creating fragments as ${APP_USER} on ${ORACLE_DATABASE}..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/${ORACLE_DATABASE}" << 'SQLEOF'

CREATE TABLE Clients1 AS
SELECT DISTINCT cl.*
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE >= 100;

ALTER TABLE Clients1 ADD PRIMARY KEY (IDCLIENT);

CREATE TABLE Commandes1 AS
SELECT DISTINCT c.*
FROM COMMANDES c
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE >= 100;

ALTER TABLE Commandes1 ADD PRIMARY KEY (IDCOMMANDE);
ALTER TABLE Commandes1 ADD CONSTRAINT fk_cmd1_client
    FOREIGN KEY (IDCLIENT) REFERENCES Clients1(IDCLIENT);

CREATE TABLE Produits1 AS
SELECT DISTINCT p.*
FROM PRODUITS p
JOIN LIGNECOMMANDES lc ON p.IDPRODUIT = lc.IDPRODUIT
WHERE lc.QUANTITE >= 100;

ALTER TABLE Produits1 ADD PRIMARY KEY (IDPRODUIT);

CREATE TABLE LigneCommandes1 AS
SELECT lc.*
FROM LIGNECOMMANDES lc
WHERE lc.QUANTITE >= 100;

ALTER TABLE LigneCommandes1 ADD PRIMARY KEY (IDLIGNECOMMANDE);
ALTER TABLE LigneCommandes1 ADD CONSTRAINT fk_lc1_cmd
    FOREIGN KEY (IDCOMMANDE) REFERENCES Commandes1(IDCOMMANDE);
ALTER TABLE LigneCommandes1 ADD CONSTRAINT fk_lc1_prod
    FOREIGN KEY (IDPRODUIT) REFERENCES Produits1(IDPRODUIT);
ALTER TABLE LigneCommandes1 ADD CONSTRAINT chk_sc2_site1_qte
    CHECK (QUANTITE >= 100);

-- Suppression des 25 lignes redondantes : le fragment LigneCommandes1 prend le relais
TRUNCATE TABLE LIGNECOMMANDES;

COMMIT;
EXIT;
SQLEOF

echo "[site1_fragments.sh] Done."
