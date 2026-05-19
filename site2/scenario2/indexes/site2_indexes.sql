-- ============================================================
-- SITE 2 - INDEXES (Scenario 2)
-- Règle fragment : QUANTITE < 100
-- Tables : LigneCommandes2, Commandes2, Clients2, Produits2
-- ============================================================

-- -------------------------------------------------------
-- 1. Index sur LigneCommandes2
-- -------------------------------------------------------
CREATE INDEX idx_lc2_quantite
    ON LigneCommandes2 (QUANTITE);

CREATE INDEX idx_lc2_idcommande
    ON LigneCommandes2 (IDCOMMANDE);

CREATE INDEX idx_lc2_idproduit
    ON LigneCommandes2 (IDPRODUIT);

CREATE INDEX idx_lc2_prod_cmd
    ON LigneCommandes2 (IDPRODUIT, IDCOMMANDE);

-- -------------------------------------------------------
-- 2. Index sur Commandes2
-- -------------------------------------------------------
CREATE INDEX idx_cmd2_idclient
    ON Commandes2 (IDCLIENT);

CREATE INDEX idx_cmd2_date
    ON Commandes2 (DATECOMMANDE);

-- -------------------------------------------------------
-- 3. Index sur Produits2
-- -------------------------------------------------------
CREATE INDEX idx_prod2_idcateg
    ON Produits2 (IDCATEG);

CREATE INDEX idx_prod2_prix
    ON Produits2 (PRIXUNITAIRE);

CREATE INDEX idx_prod2_idfour
    ON Produits2 (IDFOUR);

-- -------------------------------------------------------
-- 4. Index sur Clients2
-- -------------------------------------------------------
CREATE INDEX idx_cli2_pays
    ON Clients2 (PAYS);

CREATE INDEX idx_cli2_ville
    ON Clients2 (VILLE);

-- -------------------------------------------------------
-- VERIFICATION
-- -------------------------------------------------------
-- SELECT INDEX_NAME, TABLE_NAME, COLUMN_NAME
-- FROM USER_IND_COLUMNS
-- WHERE TABLE_NAME IN ('LIGNECOMMANDES2','COMMANDES2','PRODUITS2','CLIENTS2')
-- ORDER BY TABLE_NAME, INDEX_NAME;

COMMIT;