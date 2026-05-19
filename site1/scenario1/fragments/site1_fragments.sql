-- ============================================================
-- SITE 1 - FRAGMENTATION HORIZONTALE (Scenario 1)
-- Règle : IDCATEG = 50 AND QUANTITE > 100
-- BDD   : BDDVENTE
-- NB    : Tables suffixées _sc1 pour éviter tout conflit avec Scenario 2
-- ============================================================

-- -------------------------------------------------------
-- 1. Categories1_sc1 : catégorie du site 1
-- -------------------------------------------------------
CREATE TABLE Categories1_sc1 AS
SELECT *
FROM CATEGORIES
WHERE IDCATEG = 50;

ALTER TABLE Categories1_sc1 ADD PRIMARY KEY (IDCATEG);
ALTER TABLE Categories1_sc1 ADD CONSTRAINT chk_sc1_site1_categ
    CHECK (IDCATEG = 50);

-- -------------------------------------------------------
-- 2. Produits1_sc1 : produits de la catégorie 50
-- -------------------------------------------------------
CREATE TABLE Produits1_sc1 AS
SELECT *
FROM PRODUITS
WHERE IDCATEG = 50;

ALTER TABLE Produits1_sc1 ADD PRIMARY KEY (IDPRODUIT);
ALTER TABLE Produits1_sc1 ADD CONSTRAINT chk_sc1_site1_prod_categ
    CHECK (IDCATEG = 50);

-- -------------------------------------------------------
-- 3. LigneCommandes1_sc1 : lignes liées aux produits Site1
--    RÈGLE : IDCATEG = 50 AND QUANTITE > 100
-- -------------------------------------------------------
CREATE TABLE LigneCommandes1_sc1 AS
SELECT lc.*
FROM LIGNECOMMANDES lc
JOIN PRODUITS p ON lc.IDPRODUIT = p.IDPRODUIT
WHERE p.IDCATEG = 50 AND lc.QUANTITE > 100;

ALTER TABLE LigneCommandes1_sc1 ADD PRIMARY KEY (IDLIGNECOMMANDE);
ALTER TABLE LigneCommandes1_sc1 ADD CONSTRAINT chk_sc1_site1_qte
    CHECK (QUANTITE > 100);
ALTER TABLE LigneCommandes1_sc1 ADD CONSTRAINT fk_lc1sc1_prod
    FOREIGN KEY (IDPRODUIT) REFERENCES Produits1_sc1(IDPRODUIT);

-- -------------------------------------------------------
-- 4. Commandes1_sc1 : commandes liées aux lignes Site1
-- -------------------------------------------------------
CREATE TABLE Commandes1_sc1 AS
SELECT DISTINCT c.*
FROM COMMANDES c
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
JOIN PRODUITS p ON lc.IDPRODUIT = p.IDPRODUIT
WHERE p.IDCATEG = 50 AND lc.QUANTITE > 100;

ALTER TABLE Commandes1_sc1 ADD PRIMARY KEY (IDCOMMANDE);
ALTER TABLE LigneCommandes1_sc1 ADD CONSTRAINT fk_lc1sc1_cmd
    FOREIGN KEY (IDCOMMANDE) REFERENCES Commandes1_sc1(IDCOMMANDE);

-- -------------------------------------------------------
-- 5. Clients1_sc1 : clients liés aux commandes Site1
-- -------------------------------------------------------
CREATE TABLE Clients1_sc1 AS
SELECT DISTINCT cl.*
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
JOIN PRODUITS p ON lc.IDPRODUIT = p.IDPRODUIT
WHERE p.IDCATEG = 50 AND lc.QUANTITE > 100;

ALTER TABLE Clients1_sc1 ADD PRIMARY KEY (IDCLIENT);
ALTER TABLE Commandes1_sc1 ADD CONSTRAINT fk_cmd1sc1_client
    FOREIGN KEY (IDCLIENT) REFERENCES Clients1_sc1(IDCLIENT);

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT COUNT(*) FROM Produits1_sc1;        -- produits catégorie 50
-- SELECT COUNT(*) FROM LigneCommandes1_sc1;  -- lignes catég 50 ET quantite > 100
-- SELECT COUNT(*) FROM Commandes1_sc1;
-- SELECT COUNT(*) FROM Clients1_sc1;

COMMIT;