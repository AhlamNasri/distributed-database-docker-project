-- ============================================================
-- SITE 1 - INDEXES (Scenario 1)
-- Règle fragment : IDCATEG = 50
-- Tables : LigneCommandes1_sc1, Commandes1_sc1, Clients1_sc1,
--          Produits1_sc1, Categories1_sc1
-- ============================================================

-- -------------------------------------------------------
-- 1. Index sur Produits1_sc1
-- -------------------------------------------------------

-- Index sur IDCATEG (critère principal de fragmentation)
CREATE INDEX idx_prod1sc1_idcateg
    ON Produits1_sc1 (IDCATEG);

-- Index sur PRIXUNITAIRE (tri et filtrage par prix)
CREATE INDEX idx_prod1sc1_prix
    ON Produits1_sc1 (PRIXUNITAIRE);

-- Index sur IDFOUR (jointure avec fournisseurs)
CREATE INDEX idx_prod1sc1_idfour
    ON Produits1_sc1 (IDFOUR);

-- -------------------------------------------------------
-- 2. Index sur LigneCommandes1_sc1
-- -------------------------------------------------------

-- Index sur IDPRODUIT (critère de fragmentation indirect + jointures)
CREATE INDEX idx_lc1sc1_idproduit
    ON LigneCommandes1_sc1 (IDPRODUIT);

-- Index sur IDCOMMANDE (jointure avec Commandes1_sc1)
CREATE INDEX idx_lc1sc1_idcommande
    ON LigneCommandes1_sc1 (IDCOMMANDE);

-- Index composite (IDPRODUIT + IDCOMMANDE)
CREATE INDEX idx_lc1sc1_prod_cmd
    ON LigneCommandes1_sc1 (IDPRODUIT, IDCOMMANDE);

-- -------------------------------------------------------
-- 3. Index sur Commandes1_sc1
-- -------------------------------------------------------

-- Index sur IDCLIENT
CREATE INDEX idx_cmd1sc1_idclient
    ON Commandes1_sc1 (IDCLIENT);

-- Index sur DATECOMMANDE
CREATE INDEX idx_cmd1sc1_date
    ON Commandes1_sc1 (DATECOMMANDE);

-- -------------------------------------------------------
-- 4. Index sur Clients1_sc1
-- -------------------------------------------------------

-- Index sur PAYS
CREATE INDEX idx_cli1sc1_pays
    ON Clients1_sc1 (PAYS);

-- Index sur VILLE
CREATE INDEX idx_cli1sc1_ville
    ON Clients1_sc1 (VILLE);

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT INDEX_NAME, TABLE_NAME, COLUMN_NAME
-- FROM USER_IND_COLUMNS
-- WHERE TABLE_NAME IN ('LIGNECOMMANDES1_SC1','COMMANDES1_SC1','PRODUITS1_SC1','CLIENTS1_SC1','CATEGORIES1_SC1')
-- ORDER BY TABLE_NAME, INDEX_NAME;

COMMIT;
