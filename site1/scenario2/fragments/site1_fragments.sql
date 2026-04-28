-- ============================================================
-- SITE 1 - FRAGMENTATION HORIZONTALE (Scenario 2)
-- Règle : Quantite >= 100 (Grossistes - Entrepôt central)
-- BDD   : BDDVENTE
-- ============================================================

-- -------------------------------------------------------
-- 1. Clients1 : tous les clients liés aux commandes Site1
-- -------------------------------------------------------
CREATE TABLE Clients1 AS
SELECT DISTINCT cl.*
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE >= 100;

ALTER TABLE Clients1 ADD PRIMARY KEY (IDCLIENT);

-- -------------------------------------------------------
-- 2. Commandes1 : commandes liées aux lignes Site1
-- -------------------------------------------------------
CREATE TABLE Commandes1 AS
SELECT DISTINCT c.*
FROM COMMANDES c
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
WHERE lc.QUANTITE >= 100;

ALTER TABLE Commandes1 ADD PRIMARY KEY (IDCOMMANDE);
ALTER TABLE Commandes1 ADD CONSTRAINT fk_cmd1_client
    FOREIGN KEY (IDCLIENT) REFERENCES Clients1(IDCLIENT);

-- -------------------------------------------------------
-- 3. Produits1 : produits liés aux lignes Site1
-- -------------------------------------------------------
CREATE TABLE Produits1 AS
SELECT DISTINCT p.*
FROM PRODUITS p
JOIN LIGNECOMMANDES lc ON p.IDPRODUIT = lc.IDPRODUIT
WHERE lc.QUANTITE >= 100;

ALTER TABLE Produits1 ADD PRIMARY KEY (IDPRODUIT);

-- -------------------------------------------------------
-- 4. LigneCommandes1 : fragment principal
--    RÈGLE : Quantite >= 100
-- -------------------------------------------------------
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

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT COUNT(*) FROM LigneCommandes1;  -- doit retourner 19
-- SELECT COUNT(*) FROM Commandes1;
-- SELECT COUNT(*) FROM Clients1;
-- SELECT COUNT(*) FROM Produits1;

COMMIT;
