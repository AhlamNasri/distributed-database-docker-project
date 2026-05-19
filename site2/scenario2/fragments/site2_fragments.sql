-- ============================================================
-- SITE 2 - FRAGMENTATION HORIZONTALE (Scenario 2)
-- Règle : Quantite < 100 (Détaillants / Petites commandes)
-- BDD   : BDDVENTE2
-- ============================================================

-- -------------------------------------------------------
-- 1. Clients2 : clients liés aux commandes Site2
-- -------------------------------------------------------
CREATE TABLE Clients2 AS
SELECT DISTINCT cl.*
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE < 100;

ALTER TABLE Clients2 ADD PRIMARY KEY (IDCLIENT);

-- -------------------------------------------------------
-- 2. Commandes2 : commandes liées aux lignes Site2
-- -------------------------------------------------------
CREATE TABLE Commandes2 AS
SELECT DISTINCT c.*
FROM COMMANDES c
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE < 100;

ALTER TABLE Commandes2 ADD PRIMARY KEY (IDCOMMANDE);
ALTER TABLE Commandes2 ADD CONSTRAINT fk_cmd2_client
    FOREIGN KEY (IDCLIENT) REFERENCES Clients2(IDCLIENT);

-- -------------------------------------------------------
-- 3. Produits2 : produits liés aux lignes Site2
-- -------------------------------------------------------
CREATE TABLE Produits2 AS
SELECT DISTINCT p.*
FROM PRODUITS p
JOIN LIGNECOMMANDES lc ON p.IDPRODUIT = lc.IDPRODUIT
WHERE lc.QUANTITE < 100;

ALTER TABLE Produits2 ADD PRIMARY KEY (IDPRODUIT);

-- -------------------------------------------------------
-- 4. LigneCommandes2 : fragment principal
--    RÈGLE : Quantite < 100
-- -------------------------------------------------------
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

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT COUNT(*) FROM LigneCommandes2;   -- doit retourner le complément de Site1
-- SELECT COUNT(*) FROM Commandes2;
-- SELECT COUNT(*) FROM Clients2;
-- SELECT COUNT(*) FROM Produits2;

COMMIT;