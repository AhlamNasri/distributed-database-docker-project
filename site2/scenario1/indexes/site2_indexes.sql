-- ============================================================
-- SITE 2 - INDEXES (Scenario 1)
-- Règle fragment : IDCATEG = 35
-- Tables : LigneCommandes2_sc1, Commandes2_sc1, Clients2_sc1,
--          Produits2_sc1, Categories2_sc1
-- ============================================================

-- -------------------------------------------------------
-- 1. Index sur Produits2_sc1
-- -------------------------------------------------------
CREATE INDEX idx_prod2sc1_idcateg
    ON Produits2_sc1 (IDCATEG);

CREATE INDEX idx_prod2sc1_prix
    ON Produits2_sc1 (PRIXUNITAIRE);

CREATE INDEX idx_prod2sc1_idfour
    ON Produits2_sc1 (IDFOUR);

-- -------------------------------------------------------
-- 2. Index sur LigneCommandes2_sc1
-- -------------------------------------------------------
CREATE INDEX idx_lc2sc1_idproduit
    ON LigneCommandes2_sc1 (IDPRODUIT);

CREATE INDEX idx_lc2sc1_idcommande
    ON LigneCommandes2_sc1 (IDCOMMANDE);

CREATE INDEX idx_lc2sc1_prod_cmd
    ON LigneCommandes2_sc1 (IDPRODUIT, IDCOMMANDE);

-- -------------------------------------------------------
-- 3. Index sur Commandes2_sc1
-- -------------------------------------------------------
CREATE INDEX idx_cmd2sc1_idclient
    ON Commandes2_sc1 (IDCLIENT);

CREATE INDEX idx_cmd2sc1_date
    ON Commandes2_sc1 (DATECOMMANDE);

-- -------------------------------------------------------
-- 4. Index sur Clients2_sc1
-- -------------------------------------------------------
CREATE INDEX idx_cli2sc1_pays
    ON Clients2_sc1 (PAYS);

CREATE INDEX idx_cli2sc1_ville
    ON Clients2_sc1 (VILLE);

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT INDEX_NAME, TABLE_NAME, COLUMN_NAME
-- FROM USER_IND_COLUMNS
-- WHERE TABLE_NAME IN ('LIGNECOMMANDES2_SC1','COMMANDES2_SC1','PRODUITS2_SC1','CLIENTS2_SC1','CATEGORIES2_SC1')
-- ORDER BY TABLE_NAME, INDEX_NAME;

COMMIT;