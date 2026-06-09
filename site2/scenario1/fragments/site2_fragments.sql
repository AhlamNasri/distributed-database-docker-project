-- ============================================================
-- SITE 2 - FRAGMENTATION HORIZONTALE (Scenario 1)
-- Règle : IDCATEG = 35 (toutes quantités)
-- BDD   : BDDVENTE2
-- NB    : Tables suffixées _sc1 pour éviter conflit avec Scenario 2
--
-- CORRECTION : la règle est uniquement basée sur la CATÉGORIE.
-- La condition QUANTITE <= 100 a été supprimée car elle créait
-- une fragmentation incomplète : les enregistrements
-- IDCATEG=35 AND QUANTITE>100 n'étaient assignés à aucun site.
-- ============================================================

-- -------------------------------------------------------
-- 1. Categories2_sc1 : catégorie du site 2
-- -------------------------------------------------------
CREATE TABLE Categories2_sc1 AS
SELECT *
FROM CATEGORIES
WHERE IDCATEG = 35;

ALTER TABLE Categories2_sc1 ADD PRIMARY KEY (IDCATEG);
ALTER TABLE Categories2_sc1 ADD CONSTRAINT chk_sc1_site2_categ
    CHECK (IDCATEG = 35);

-- -------------------------------------------------------
-- 2. Produits2_sc1 : produits de la catégorie 35
-- -------------------------------------------------------
CREATE TABLE Produits2_sc1 AS
SELECT *
FROM PRODUITS
WHERE IDCATEG = 35;

ALTER TABLE Produits2_sc1 ADD PRIMARY KEY (IDPRODUIT);
ALTER TABLE Produits2_sc1 ADD CONSTRAINT chk_sc1_site2_prod_categ
    CHECK (IDCATEG = 35);

-- -------------------------------------------------------
-- 3. LigneCommandes2_sc1 : toutes les lignes liées
--    aux produits de catégorie 35 (sans condition sur quantité)
-- -------------------------------------------------------
CREATE TABLE LigneCommandes2_sc1 AS
SELECT lc.*
FROM LIGNECOMMANDES lc
JOIN PRODUITS p ON lc.IDPRODUIT = p.IDPRODUIT
WHERE p.IDCATEG = 35;

ALTER TABLE LigneCommandes2_sc1 ADD PRIMARY KEY (IDLIGNECOMMANDE);
ALTER TABLE LigneCommandes2_sc1 ADD CONSTRAINT fk_lc2sc1_prod
    FOREIGN KEY (IDPRODUIT) REFERENCES Produits2_sc1(IDPRODUIT);

-- -------------------------------------------------------
-- 4. Commandes2_sc1 : commandes liées aux lignes Site2
-- -------------------------------------------------------
CREATE TABLE Commandes2_sc1 AS
SELECT DISTINCT c.*
FROM COMMANDES c
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
JOIN PRODUITS p ON lc.IDPRODUIT = p.IDPRODUIT
WHERE p.IDCATEG = 35;

ALTER TABLE Commandes2_sc1 ADD PRIMARY KEY (IDCOMMANDE);
ALTER TABLE LigneCommandes2_sc1 ADD CONSTRAINT fk_lc2sc1_cmd
    FOREIGN KEY (IDCOMMANDE) REFERENCES Commandes2_sc1(IDCOMMANDE);

-- -------------------------------------------------------
-- 5. Clients2_sc1 : clients liés aux commandes Site2
-- -------------------------------------------------------
CREATE TABLE Clients2_sc1 AS
SELECT DISTINCT cl.*
FROM CLIENTS cl
JOIN COMMANDES c ON cl.IDCLIENT = c.IDCLIENT
JOIN LIGNECOMMANDES lc ON c.IDCOMMANDE = lc.IDCOMMANDE
JOIN PRODUITS p ON lc.IDPRODUIT = p.IDPRODUIT
WHERE p.IDCATEG = 35;

ALTER TABLE Clients2_sc1 ADD PRIMARY KEY (IDCLIENT);
ALTER TABLE Commandes2_sc1 ADD CONSTRAINT fk_cmd2sc1_client
    FOREIGN KEY (IDCLIENT) REFERENCES Clients2_sc1(IDCLIENT);

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT COUNT(*) FROM Produits2_sc1;        -- 3 produits catégorie 35
-- SELECT COUNT(*) FROM LigneCommandes2_sc1;  -- 10 lignes (IDPRODUIT 4,5,6)
-- SELECT COUNT(*) FROM Commandes2_sc1;       -- commandes 6,7,8
-- SELECT COUNT(*) FROM Clients2_sc1;         -- clients 4,5,6

COMMIT;
